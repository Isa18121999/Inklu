import 'package:flutter/material.dart';
import 'api_service.dart';

const _purple = Color(0xFF4F46E5);
const _muted = Color(0xFF64748B);

class AccessibilityPreferencesPage extends StatefulWidget {
  final String token;
  const AccessibilityPreferencesPage({super.key, required this.token});

  @override
  State<AccessibilityPreferencesPage> createState() => _AccessibilityPreferencesPageState();
}

class _AccessibilityPreferencesPageState extends State<AccessibilityPreferencesPage> {
  final _api = ApiService();
  bool loading = true;
  bool saving = false;
  bool shareAccessibility = false;
  String needType = '';
  final selected = <String>{};

  static const needs = ['Movilidad', 'Visual', 'Auditiva', 'Cognitiva', 'Comunicación', 'Otra', 'Prefiero no indicarlo'];
  static const preferences = [
    'Trabajo remoto', 'Trabajo híbrido', 'Horario flexible', 'Acceso sin escaleras',
    'Ascensor', 'Baño accesible', 'Estacionamiento accesible', 'Adaptación del puesto',
    'Tecnología asistiva', 'Intérprete', 'Apoyo para desplazamiento', 'Otro'
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _api.accessibilityProfile(widget.token);
      final a = Map<String, dynamic>.from((data['accessibility'] as Map?) ?? {});
      setState(() {
        shareAccessibility = a['share'] == true;
        needType = a['needType']?.toString() ?? '';
        selected
          ..clear()
          ..addAll((a['preferences'] as List? ?? const []).map((e) => e.toString()));
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await _api.updateAccessibilityProfile(widget.token, {
        'share': shareAccessibility,
        'needType': needType,
        'preferences': selected.toList(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias de accesibilidad guardadas.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Accesibilidad')),
    body: loading ? const Center(child: CircularProgressIndicator(color: _purple)) : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tus necesidades y preferencias', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Esta información es opcional. Tú decides si INKLU puede usarla para encontrar oportunidades compatibles.', style: TextStyle(color: _muted, height: 1.45)),
        const SizedBox(height: 18),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Usar mis preferencias para recomendar ofertas', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('No se utilizará tu discapacidad para reducir tu compatibilidad.', style: TextStyle(color: _muted)),
          value: shareAccessibility,
          onChanged: (v) => setState(() => shareAccessibility = v),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: needType.isEmpty ? null : needType,
          decoration: const InputDecoration(labelText: 'Tipo de necesidad de accesibilidad (opcional)', border: OutlineInputBorder()),
          items: needs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => needType = v ?? ''),
        ),
        const SizedBox(height: 20),
        const Text('¿Qué condiciones o ajustes necesitas?', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...preferences.map((item) => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item),
          value: selected.contains(item),
          onChanged: (v) => setState(() => v == true ? selected.add(item) : selected.remove(item)),
        )),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Guardando...' : 'Guardar preferencias'),
        ),
      ],
    ),
  );
}

Future<void> showJobReportDialog(BuildContext context, String token, String jobId) async {
  String reason = 'Información falsa';
  final details = TextEditingController();
  const reasons = ['Información falsa', 'Empresa sospechosa', 'Discriminación', 'Accesibilidad indicada no disponible', 'Requisitos discriminatorios', 'Salario engañoso', 'Otro'];
  final sent = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reportar oferta'),
      content: StatefulBuilder(builder: (context, setState) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Align(alignment: Alignment.centerLeft, child: Text('¿Qué deseas reportar?', style: TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: reason, items: reasons.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => reason = v ?? reason)),
        const SizedBox(height: 12),
        TextField(controller: details, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Enviar reporte')),
      ],
    ),
  );
  if (sent != true) { details.dispose(); return; }
  try {
    await ApiService().reportJob(token, jobId, reason: reason, details: details.text.trim());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte recibido. Gracias por ayudar a mantener INKLU segura e inclusiva.')));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
  } finally { details.dispose(); }
}
