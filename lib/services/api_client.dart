import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../config/sistemas_catalog.dart';
import '../models/app_user.dart';
import '../models/models.dart';
import '../utils/attachment_files.dart';
import 'mock_data_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient();

  String? _access;
  String? _refresh;
  AppUser? currentUser;
  final MockDataStore _mock = MockDataStore();

  String? get accessToken => _access;
  bool get isMock => ApiConfig.useMock;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString('gp_access');
    _refresh = prefs.getString('gp_refresh');
    final userJson = prefs.getString('gp_user');
    if (userJson != null) {
      currentUser = AppUser.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
    }
    // Rehidratar puesto/área desde API (la sesión cacheada puede no tenerlos).
    if (_access != null && currentUser != null) {
      try {
        await refreshPerfil();
      } catch (_) {}
    }
  }

  /// Perfil GP + complemento de ExtendedUsers (/users/{id}/) para puesto_id.
  Future<void> refreshPerfil() async {
    if (_access == null) return;
    currentUser = AppUser.fromJson(await _get(ApiConfig.perfilPath));
    await _enrichPuestoFromUsers();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_access != null) {
      await prefs.setString('gp_access', _access!);
    } else {
      await prefs.remove('gp_access');
    }
    if (_refresh != null) {
      await prefs.setString('gp_refresh', _refresh!);
    } else {
      await prefs.remove('gp_refresh');
    }
    if (currentUser != null) {
      // Minimal persist for boot; full user re-fetched on login
      await prefs.setString(
        'gp_user',
        jsonEncode({
          'id': currentUser!.id,
          'username': currentUser!.username,
          'first_name': currentUser!.firstName,
          'last_name': currentUser!.lastName,
          'email': currentUser!.email,
          'groups': currentUser!.groups,
          'area': currentUser!.area,
          'area_id': currentUser!.areaId,
          'puesto': currentUser!.puesto,
          'is_staff': currentUser!.isStaff,
          'es_gestor': currentUser!.esGestor,
          'es_lider': currentUser!.esLider,
          'es_desarrollador': currentUser!.esDesarrollador,
        }),
      );
    } else {
      await prefs.remove('gp_user');
    }
  }

  Future<void> clearSession() async {
    _access = null;
    _refresh = null;
    currentUser = null;
    await _persist();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<AppUser> login(String username, String password) async {
    final res = await http.post(
      _uri(ApiConfig.tokenPath),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    final data = _decodeJsonMap(res);
    _access = data['access'] as String?;
    _refresh = data['refresh'] as String?;
    if (_access == null) {
      throw ApiException(
        res.statusCode,
        'Login OK pero el servidor no devolvió access token.',
      );
    }
    final userMap = data['user'] as Map<String, dynamic>?;
    currentUser = userMap != null
        ? AppUser.fromJson(userMap)
        : AppUser(id: 0, username: username);
    // El rol lo decide el backend: /api/token/ no incluye los grupos.
    try {
      currentUser = AppUser.fromJson(await _get(ApiConfig.perfilPath));
      // me/ a veces no resuelve puesto; /users/{id}/ sí trae puesto_id.nombre.
      await _enrichPuestoFromUsers();
    } on ApiException {
      // En mock, GP_* puede no estar desplegado todavía: caer al scraping de /users/.
      if (!ApiConfig.useMock) rethrow;
      await _enrichUserGroups();
    }
    await _persist();
    return currentUser!;
  }

  /// Completa puesto desde ExtendedUsers en /users/{id}/ (fuente real en prod).
  Future<void> _enrichPuestoFromUsers() async {
    if (currentUser == null || _access == null) return;
    final already = currentUser!.puesto?.trim();
    if (already != null && already.isNotEmpty) return;
    try {
      final first = await _get('${ApiConfig.usersPath}${currentUser!.id}/');
      final puestoId = first['puesto_id'];
      final puesto = puestoId is Map
          ? (puestoId['nombre'] as String?)?.trim()
          : null;
      if (puesto == null || puesto.isEmpty) return;

      final areaId = first['area_id'];
      final areaFromId = areaId is Map ? areaId['nombre'] as String? : null;

      currentUser = AppUser(
        id: currentUser!.id,
        username: currentUser!.username,
        firstName: currentUser!.firstName,
        lastName: currentUser!.lastName,
        email: currentUser!.email,
        groups: currentUser!.groups,
        area: currentUser!.area ?? areaFromId ?? first['area'] as String?,
        areaId: currentUser!.areaId ??
            (areaId is Map ? areaId['id'] as int? : areaId as int?),
        puesto: puesto,
        isStaff: currentUser!.isStaff,
        esGestor: currentUser!.esGestor,
        esLider: currentUser!.esLider,
        esDesarrollador: currentUser!.esDesarrollador,
      );
    } catch (_) {
      // Sin puesto: la UI muestra "—".
    }
  }

  /// Fallback solo para modo mock, mientras `GP_Usuario` no exista en el servidor.
  Future<void> _enrichUserGroups() async {
    if (currentUser == null || _access == null) return;
    try {
      final res = await _get(
        ApiConfig.usersPath,
        query: {'username': currentUser!.username, 'format': 'json'},
      );
      final results = res['results'] as List? ?? [res];
      if (results.isEmpty) return;
      final first = results.first as Map<String, dynamic>;
      // groups pueden ser URLs; pedir /groups/ y mapear IDs si hace falta
      final groupUrls = first['groups'];
      final names = <String>[];
      if (groupUrls is List) {
        for (final g in groupUrls) {
          if (g is String && g.contains('/groups/')) {
            final id = RegExp(r'/groups/(\d+)/').firstMatch(g)?.group(1);
            if (id != null) {
              try {
                final gRes = await http.get(
                  _uri('/groups/$id/'),
                  headers: _authHeaders(),
                );
                if (gRes.statusCode == 200) {
                  final gData = jsonDecode(gRes.body) as Map<String, dynamic>;
                  final name = gData['name'] as String?;
                  if (name != null) names.add(name);
                }
              } catch (_) {}
            }
          } else if (g is String) {
            names.add(g);
          }
        }
      }
      currentUser = AppUser(
        id: first['id'] as int? ?? currentUser!.id,
        username: (first['username'] ?? currentUser!.username) as String,
        firstName: (first['first_name'] ?? currentUser!.firstName) as String,
        lastName: (first['last_name'] ?? currentUser!.lastName) as String,
        email: (first['email'] ?? currentUser!.email) as String,
        groups: names.isNotEmpty ? names : currentUser!.groups,
        area: first['area_id'] is Map
            ? (first['area_id'] as Map)['nombre'] as String? ??
                  currentUser!.area
            : first['area'] as String? ?? currentUser!.area,
        areaId: first['area_id'] is Map
            ? (first['area_id'] as Map)['id'] as int?
            : first['area_id'] as int? ?? currentUser!.areaId,
        puesto: first['puesto_id'] is Map
            ? (first['puesto_id'] as Map)['nombre'] as String?
            : currentUser!.puesto,
        isStaff: first['is_staff'] == true || currentUser!.isStaff,
      );
    } catch (_) {
      // Mantener user del token
    }
  }

  Future<bool> tryRefresh() async {
    if (_refresh == null) return false;
    final res = await http.post(
      _uri(ApiConfig.refreshPath),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'refresh': _refresh}),
    );
    if (res.statusCode != 200) {
      await clearSession();
      return false;
    }
    try {
      final data = _decodeJsonMap(res);
      _access = data['access'] as String?;
      await _persist();
      return _access != null;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Map<String, String> _authHeaders({bool json = true}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (_access != null) h['Authorization'] = 'Bearer $_access';
    return h;
  }

  Map<String, dynamic> _decodeJsonMap(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) {
      throw ApiException(res.statusCode, 'Respuesta vacía del servidor.');
    }
    if (body.startsWith('<!') || body.startsWith('<html')) {
      throw ApiException(
        res.statusCode,
        'El servidor devolvió HTML en vez de JSON (¿falta Accept o la ruta es incorrecta?).',
      );
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException(
        res.statusCode,
        'JSON inesperado: ${decoded.runtimeType}',
      );
    } on FormatException catch (e) {
      throw ApiException(res.statusCode, 'JSON inválido: ${e.message}');
    }
  }

  String _errorMessage(http.Response res) {
    final body = res.body.trim();
    if (body.startsWith('<!') || body.startsWith('<html')) {
      return 'Error ${res.statusCode}: el API respondió HTML (pide Accept: application/json).';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['detail'] != null) return decoded['detail'].toString();
        // simplejwt a veces: {"non_field_errors":[...]}
        if (decoded['non_field_errors'] is List &&
            (decoded['non_field_errors'] as List).isNotEmpty) {
          return (decoded['non_field_errors'] as List).first.toString();
        }
        return decoded.toString();
      }
    } catch (_) {}
    if (body.isEmpty) return 'Error ${res.statusCode}';
    return body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    var res = await call();
    if (res.statusCode == 401) {
      final ok = await tryRefresh();
      if (ok) res = await call();
    }
    return res;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _send(
      () => http.get(_uri(path, query), headers: _authHeaders()),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    if (res.body.isEmpty) return {};
    final body = res.body.trim();
    if (body.startsWith('<!') || body.startsWith('<html')) {
      throw ApiException(
        res.statusCode,
        'El servidor devolvió HTML en vez de JSON.',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is List) return {'results': decoded};
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _send(
      () => http.post(
        _uri(path),
        headers: _authHeaders(),
        body: jsonEncode(body),
      ),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    return _decodeJsonMap(res);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _send(
      () => http.patch(
        _uri(path),
        headers: _authHeaders(),
        body: jsonEncode(body),
      ),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    return _decodeJsonMap(res);
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic> data) {
    final r = data['results'];
    if (r is List) {
      return r.cast<Map<String, dynamic>>();
    }
    return [data];
  }

  int get _userId => currentUser?.id ?? 3;
  String get _userName => currentUser?.fullName ?? 'Usuario mock';

  Future<InboxStats> fetchInbox() async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final u = currentUser;
      return _mock.inbox(
        userId: _userId,
        userAreaId: u?.areaId,
        isGestor: u?.isGestor ?? false,
        isLider: u?.isLider ?? false,
        isDesarrollador: u?.isDesarrollador ?? false,
      );
    }
    final data = await _get(ApiConfig.inboxPath);
    return InboxStats.fromJson(data);
  }

  Future<List<Ticket>> fetchTickets({Map<String, String>? filters}) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final u = currentUser;
      return _mock.listTickets(
        filters,
        userId: _userId,
        userAreaId: u?.areaId,
        isGestor: u?.isGestor ?? false,
        isDesarrollador: u?.isDesarrollador ?? false,
      );
    }
    final data = await _get(
      ApiConfig.ticketsPath,
      query: {'format': 'json', ...?filters},
    );
    return _results(data).map(Ticket.fromJson).toList();
  }

  Future<Ticket> fetchTicket(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        return _mock.getTicket(id);
      } catch (_) {
        throw ApiException(404, 'Ticket $id no encontrado (mock)');
      }
    }
    final data = await _get('${ApiConfig.ticketsPath}$id/');
    return Ticket.fromJson(data);
  }

  Future<Ticket> createTicket(Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _mock.createTicket(body, userId: _userId, userName: _userName);
    }
    // `adjuntos` es read_only en el serializer: se sube por multipart tras crear.
    final payload = Map<String, dynamic>.from(body)..remove('adjuntos');
    final adjuntos = _adjuntosFrom(body['adjuntos']);
    final data = await _post(ApiConfig.ticketsPath, payload);
    var ticket = Ticket.fromJson(data);
    for (final adj in adjuntos) {
      ticket = await addAdjunto(ticket.id, adj);
    }
    return ticket;
  }

  List<TicketAdjunto> _adjuntosFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <TicketAdjunto>[];
    for (final a in raw) {
      if (a is TicketAdjunto) {
        out.add(a);
      } else if (a is Map) {
        out.add(TicketAdjunto.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return out;
  }

  MediaType _mediaTypeFor(TicketAdjunto adjunto) {
    final raw = (adjunto.mimeType != null && adjunto.mimeType!.isNotEmpty)
        ? adjunto.mimeType!
        : mimeFromFileName(adjunto.nombre);
    try {
      return MediaType.parse(raw);
    } catch (_) {
      return MediaType('application', 'octet-stream');
    }
  }

  Future<Ticket> updateTicket(int id, Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        String? assignName;
        if (body.containsKey('asignado_a') && body['asignado_a'] != null) {
          final aid = body['asignado_a'] as int;
          assignName = aid == _userId ? _userName : _mock.nameForUser(aid);
        }
        return _mock.updateTicket(
          id,
          body,
          assignName: assignName,
          actorId: _userId,
          actorName: _userName,
        );
      } catch (_) {
        throw ApiException(404, 'Ticket $id no encontrado (mock)');
      }
    }
    final data = await _patch('${ApiConfig.ticketsPath}$id/', body);
    return Ticket.fromJson(data);
  }

  /// Elimina un ticket. En backend requiere líder/gestor (403 si no).
  Future<void> deleteTicket(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      try {
        _mock.deleteTicket(id);
      } on StateError catch (e) {
        throw ApiException(404, e.message);
      }
      return;
    }
    final res = await _send(
      () => http.delete(
        _uri('${ApiConfig.ticketsPath}$id/'),
        headers: _authHeaders(json: false),
      ),
    );
    if (res.statusCode >= 400)
      throw ApiException(res.statusCode, _errorMessage(res));
  }

  /// Sube un adjunto al ticket. Devuelve el ticket actualizado.
  Future<Ticket> addAdjunto(int ticketId, TicketAdjunto adjunto) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final cur = _mock.getTicket(ticketId);
      return _mock.updateTicket(ticketId, {
        'adjuntos': [...cur.adjuntos, adjunto],
      });
    }
    // Envío multipart al backend
    final uri = _uri('${ApiConfig.ticketsPath}$ticketId/adjuntos/');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(json: false));
    // adjunto.url es una data URL → extraer bytes
    if (adjunto.url.startsWith('data:')) {
      final comma = adjunto.url.indexOf(',');
      if (comma > 0) {
        final bytes = base64Decode(adjunto.url.substring(comma + 1));
        request.files.add(
          http.MultipartFile.fromBytes(
            'archivo',
            bytes,
            filename: adjunto.nombre,
            contentType: _mediaTypeFor(adjunto),
          ),
        );
      }
    }
    final streamed = await _send(
      () async => http.Response.fromStream(await request.send()),
    );
    if (streamed.statusCode >= 400)
      throw ApiException(streamed.statusCode, _errorMessage(streamed));
    // Recargar el ticket completo para tener la lista de adjuntos actualizada
    final data = await _get('${ApiConfig.ticketsPath}$ticketId/');
    return Ticket.fromJson(data);
  }

  /// Elimina un adjunto. Devuelve el ticket actualizado.
  Future<Ticket> removeAdjunto(int ticketId, String adjuntoId) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final cur = _mock.getTicket(ticketId);
      return _mock.updateTicket(ticketId, {
        'adjuntos': cur.adjuntos.where((a) => a.id != adjuntoId).toList(),
      });
    }
    final res = await _send(
      () => http.delete(
        _uri('${ApiConfig.ticketsPath}$ticketId/adjuntos/$adjuntoId/'),
        headers: _authHeaders(json: false),
      ),
    );
    if (res.statusCode >= 400)
      throw ApiException(res.statusCode, _errorMessage(res));
    final data = await _get('${ApiConfig.ticketsPath}$ticketId/');
    return Ticket.fromJson(data);
  }

  /// Toma un ticket de la cola (asignarse + en_proceso si era nuevo).
  Future<Ticket> takeTicket(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        return _mock.takeTicket(id, userId: _userId, userName: _userName);
      } on StateError catch (e) {
        throw ApiException(409, e.message);
      } catch (_) {
        throw ApiException(404, 'Ticket $id no encontrado (mock)');
      }
    }
    final data = await _post('${ApiConfig.ticketsPath}$id/tomar/', {});
    return Ticket.fromJson(data);
  }

  /// Catálogo de áreas de la organización.
  Future<List<AreaOption>> fetchAreas() async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return _mock.listAreas();
    }
    try {
      final data = await _get(ApiConfig.areasPath, query: {'format': 'json'});
      return _results(data).map(AreaOption.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Usuarios a los que se puede asignar un ticket o una tarea.
  Future<List<AssignableUser>> fetchAssignableUsers({String? query}) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final list = _mock.listAssignableUsers(query: query);
      // Incluye al usuario logueado si no está en el catálogo (id real del JWT).
      final me = currentUser;
      if (me != null &&
          (query == null || query.isEmpty) &&
          !list.any((u) => u.id == me.id)) {
        return [
          AssignableUser(
            id: me.id,
            fullName: me.fullName,
            username: me.username,
            rol: 'Yo',
          ),
          ...list,
        ];
      }
      return list;
    }
    final q = query?.trim();
    final data = await _get(
      ApiConfig.usuariosPath,
      query: {'format': 'json', if (q != null && q.isNotEmpty) 'q': q},
    );
    return _results(data).map(AssignableUser.fromJson).toList();
  }

  /// Sube un adjunto a un proyecto. Devuelve el proyecto actualizado.
  Future<Proyecto> addProyectoAdjunto(
    int proyectoId,
    TicketAdjunto adjunto,
  ) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final cur = _mock.getProyecto(proyectoId);
      return _mock.updateProyecto(proyectoId, {
        'adjuntos': [...cur.adjuntos, adjunto],
      });
    }
    final uri = _uri('${ApiConfig.proyectosPath}$proyectoId/adjuntos/');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(json: false));
    if (adjunto.url.startsWith('data:')) {
      final comma = adjunto.url.indexOf(',');
      if (comma > 0) {
        final bytes = base64Decode(adjunto.url.substring(comma + 1));
        request.files.add(
          http.MultipartFile.fromBytes(
            'archivo',
            bytes,
            filename: adjunto.nombre,
            contentType: _mediaTypeFor(adjunto),
          ),
        );
      }
    }
    final streamed = await _send(
      () async => http.Response.fromStream(await request.send()),
    );
    if (streamed.statusCode >= 400)
      throw ApiException(streamed.statusCode, _errorMessage(streamed));
    final data = await _get('${ApiConfig.proyectosPath}$proyectoId/');
    return Proyecto.fromJson(data);
  }

  /// Elimina un adjunto de un proyecto. Devuelve el proyecto actualizado.
  Future<Proyecto> removeProyectoAdjunto(
    int proyectoId,
    String adjuntoId,
  ) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final cur = _mock.getProyecto(proyectoId);
      return _mock.updateProyecto(proyectoId, {
        'adjuntos': cur.adjuntos.where((a) => a.id != adjuntoId).toList(),
      });
    }
    final res = await _send(
      () => http.delete(
        _uri('${ApiConfig.proyectosPath}$proyectoId/adjuntos/$adjuntoId/'),
        headers: _authHeaders(json: false),
      ),
    );
    if (res.statusCode >= 400)
      throw ApiException(res.statusCode, _errorMessage(res));
    final data = await _get('${ApiConfig.proyectosPath}$proyectoId/');
    return Proyecto.fromJson(data);
  }

  Future<List<Proyecto>> fetchProyectos({Map<String, String>? filters}) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final u = currentUser;
      return _mock.listProyectos(
        filters,
        userId: _userId,
        userAreaId: u?.areaId,
        isGestor: u?.isGestor ?? false,
        isLider: u?.isLider ?? false,
        isDesarrollador: u?.isDesarrollador ?? false,
      );
    }
    final data = await _get(
      ApiConfig.proyectosPath,
      query: {'format': 'json', ...?filters},
    );
    return _results(data).map(Proyecto.fromJson).toList();
  }

  Future<Proyecto> fetchProyecto(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        return _mock.getProyecto(id);
      } catch (_) {
        throw ApiException(404, 'Proyecto $id no encontrado (mock)');
      }
    }
    final data = await _get('${ApiConfig.proyectosPath}$id/');
    return Proyecto.fromJson(data);
  }

  Future<Proyecto> createProyecto(Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _mock.createProyecto(body, userId: _userId, userName: _userName);
    }
    final data = await _post(ApiConfig.proyectosPath, body);
    return Proyecto.fromJson(data);
  }

  Future<Proyecto> updateProyecto(int id, Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        return _mock.updateProyecto(
          id,
          body,
          actorId: _userId,
          actorName: _userName,
        );
      } catch (_) {
        throw ApiException(404, 'Proyecto $id no encontrado (mock)');
      }
    }
    final data = await _patch('${ApiConfig.proyectosPath}$id/', body);
    return Proyecto.fromJson(data);
  }

  /// Elimina un proyecto. En backend requiere líder/gestor (403 si no).
  Future<void> deleteProyecto(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      try {
        _mock.deleteProyecto(id);
      } on StateError catch (e) {
        throw ApiException(404, e.message);
      }
      return;
    }
    final res = await _send(
      () => http.delete(
        _uri('${ApiConfig.proyectosPath}$id/'),
        headers: _authHeaders(json: false),
      ),
    );
    if (res.statusCode >= 400)
      throw ApiException(res.statusCode, _errorMessage(res));
  }

  Future<List<Comentario>> fetchComentarios(String tipo, int refId) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return _mock.listComentarios(tipo, refId);
    }
    final data = await _get(
      ApiConfig.comentariosPath,
      query: {'tipo': tipo, 'ref_id': '$refId', 'format': 'json'},
    );
    return _results(data).map(Comentario.fromJson).toList();
  }

  Future<Comentario> createComentario(
    String tipo,
    int refId,
    String cuerpo,
  ) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return _mock.createComentario(
        tipo,
        refId,
        cuerpo,
        userId: _userId,
        userName: _userName,
      );
    }
    final data = await _post(ApiConfig.comentariosPath, {
      'tipo': tipo,
      'ref_id': refId,
      'cuerpo': cuerpo,
    });
    return Comentario.fromJson(data);
  }

  Future<List<HistorialEstado>> fetchHistorial(String tipo, int refId) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return _mock.listHistorial(tipo, refId);
    }
    final data = await _get(
      ApiConfig.historialPath,
      query: {'tipo': tipo, 'ref_id': '$refId', 'format': 'json'},
    );
    final items = _results(data).map(HistorialEstado.fromJson).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return items;
  }

  // ── Tareas ────────────────────────────────────────────────────────────

  Future<List<Tarea>> fetchTareas({int? proyectoId}) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return _mock.listTareas(proyectoId: proyectoId);
    }
    final query = <String, String>{'format': 'json'};
    if (proyectoId != null) query['proyecto'] = '$proyectoId';
    final data = await _get(ApiConfig.tareasPath, query: query);
    return _results(data).map(Tarea.fromJson).toList();
  }

  Future<Tarea> createTarea(Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final asignadoId = body['asignado_a'] as int?;
      final asignadoNombre = asignadoId != null
          ? _mock.nameForUser(asignadoId)
          : null;
      return _mock.createTarea(
        body,
        asignadoNombre: asignadoNombre,
        actorId: _userId,
        actorName: _userName,
      );
    }
    final data = await _post(ApiConfig.tareasPath, body);
    return Tarea.fromJson(data);
  }

  Future<Tarea> updateTarea(int id, Map<String, dynamic> body) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        String? asignadoNombre;
        if (body.containsKey('asignado_a') && body['asignado_a'] != null) {
          final aid = body['asignado_a'] as int;
          asignadoNombre = aid == _userId ? _userName : _mock.nameForUser(aid);
        }
        return _mock.updateTarea(
          id,
          body,
          asignadoNombre: asignadoNombre,
          actorId: _userId,
          actorName: _userName,
        );
      } catch (_) {
        throw ApiException(404, 'Tarea $id no encontrada (mock)');
      }
    }
    final data = await _patch('${ApiConfig.tareasPath}$id/', body);
    return Tarea.fromJson(data);
  }

  Future<void> deleteTarea(int id) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _mock.deleteTarea(id);
      return;
    }
    final res = await _send(
      () => http.delete(
        _uri('${ApiConfig.tareasPath}$id/'),
        headers: _authHeaders(json: false),
      ),
    );
    if (res.statusCode >= 400)
      throw ApiException(res.statusCode, _errorMessage(res));
  }

  Future<ProductividadReport> fetchProductividad({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _mock.productividad(desde: desde, hasta: hasta);
    }
    final data = await _get(
      ApiConfig.productividadPath,
      query: {'desde': fmt(desde), 'hasta': fmt(hasta), 'format': 'json'},
    );
    return ProductividadReport.fromJson(data);
  }

  /// Catálogo de sistemas afectados. En mock usa la lista local.
  Future<List<SistemaOption>> fetchSistemas({bool soloActivos = true}) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return List<SistemaOption>.from(SistemaAfectadoCatalog.options);
    }
    final query = <String, String>{'format': 'json'};
    if (soloActivos) query['activo'] = 'true';
    final data = await _get(ApiConfig.sistemasPath, query: query);
    return _results(data)
        .map((j) {
          return SistemaOption(
            value: (j['codigo'] ?? '') as String,
            label: (j['nombre'] ?? '') as String,
            hint: (j['descripcion'] as String?)?.isNotEmpty == true
                ? j['descripcion'] as String
                : null,
          );
        })
        .where((o) => o.value.isNotEmpty)
        .toList();
  }
}
