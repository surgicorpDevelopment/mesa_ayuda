import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'router.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestorApp());
}

class GestorApp extends StatefulWidget {
  const GestorApp({super.key});

  @override
  State<GestorApp> createState() => _GestorAppState();
}

class _GestorAppState extends State<GestorApp> {
  late final ApiClient _api;
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthProvider(_api);
    _router = createRouter(_auth);
    _auth.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'Mesa de Ayuda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
