/// Catálogo de sistemas / aplicaciones internas Surgicorp.
/// Ampliar aquí cuando salgan nuevos módulos.
class SistemaAfectadoCatalog {
  SistemaAfectadoCatalog._();

  static const List<SistemaOption> options = [
    SistemaOption(value: 'hoja_picking', label: 'Hoja de Picking'),
    SistemaOption(value: 'rotulado_bultos', label: 'Rotulado de Bultos'),
    SistemaOption(value: 'vacaciones', label: 'Vacaciones'),
    SistemaOption(value: 'caja_chica', label: 'Caja Chica'),
    SistemaOption(value: 'stock_inventario', label: 'Stock / Inventario'),
    SistemaOption(value: 'licitaciones', label: 'Licitaciones'),
    SistemaOption(value: 'comisiones', label: 'Comisiones'),
    SistemaOption(value: 'cotizaciones', label: 'Cotizaciones'),
    SistemaOption(value: 'facturacion', label: 'Facturación'),
    SistemaOption(value: 'whatsapp', label: 'WhatsApp / Integraciones'),
    SistemaOption(
      value: 'power_apps',
      label: 'Power Apps (apps de negocio)',
      hint: 'Cubre las ~10 apps de Power Platform',
    ),
    SistemaOption(value: 'erp', label: 'ERP / Guías / Pedidos'),
    SistemaOption(value: 'n8n', label: 'Automatizaciones (n8n)'),
    SistemaOption(value: 'otro', label: 'Otro…'),
  ];

  static String labelFor(String value) {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return value;
  }
}

class SistemaOption {
  const SistemaOption({
    required this.value,
    required this.label,
    this.hint,
  });

  final String value;
  final String label;
  final String? hint;
}
