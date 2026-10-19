import 'package:flutter/material.dart';
import 'services/api_service.dart';

const _primary = Color(0xFF4F46E5);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);

class CreateOfferPage extends StatefulWidget {
  final String token;
  final ApiService api;
  final VoidCallback? onPublished;

  const CreateOfferPage({
    super.key,
    required this.token,
    required this.api,
    this.onPublished,
  });

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final experience = TextEditingController(text: '0');
  final requiredSkills = TextEditingController();
  final preferredSkills = TextEditingController();
  final accessibilityDetails = TextEditingController();
  final salary = TextEditingController();
  final location = TextEditingController(text: 'Lima, Perú');

  static const modalities = ['Remoto', 'Híbrido', 'Presencial'];
  static const categories = ['Tecnología', 'Administración', 'Diseño', 'Atención al cliente', 'Educación', 'Salud', 'Finanzas', 'Logística', 'Marketing', 'Otro'];
  static const contracts = ['Tiempo completo', 'Medio tiempo', 'Temporal', 'Prácticas', 'Freelance', 'Por horas'];

  String modality = 'Remoto';
  String category = 'Tecnología';
  String contractType = 'Tiempo completo';
  bool workplaceAdaptation = false;
  bool assistiveTechnology = false;
  bool flexibleSchedule = false;
  bool physicalAccess = false;
  bool elevator = false;
  bool accessibleParking = false;
  bool publishing = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    experience.dispose();
    requiredSkills.dispose();
    preferredSkills.dispose();
    accessibilityDetails.dispose();
    salary.dispose();
    location.dispose();
    super.dispose();
  }

  Widget field(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      label: label,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      ),
    ),
  );

  Widget dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Semantics(
      label: label,
      button: true,
      value: value,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        ),
        items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  /// Etiquetas semánticas en español para Voice Access/TalkBack.
  /// El nombre accesible es el mismo que ve la persona en pantalla.
  Widget accessibilityTile({required String title, required bool value, required ValueChanged<bool?> onChanged}) => Semantics(
    container: true,
    label: title,
    checked: value,
    hint: value ? 'Activado. Toca para desactivar.' : 'Desactivado. Toca para activar.',
    child: CheckboxListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: _primary,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
    ),
  );

  Future<void> publish() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa el título y la descripción del puesto.')));
      return;
    }
    final years = int.tryParse(experience.text.trim());
    if (years == null || years < 0 || years > 60) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La experiencia debe estar entre 0 y 60 años.')));
      return;
    }
    setState(() => publishing = true);
    try {
      await widget.api.createJob(widget.token, {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'location': location.text.trim(),
        'category': category,
        'modality': modality,
        'contractType': contractType,
        'experienceRequired': years,
        'requiredSkills': requiredSkills.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).take(40).toList(),
        'preferredSkills': preferredSkills.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).take(40).toList(),
        'accessibilityDetails': accessibilityDetails.text.trim(),
        'accessibility': {
          'remote': modality.toLowerCase().contains('remoto'),
          'hybrid': modality.toLowerCase().contains('híbrido') || modality.toLowerCase().contains('hibrido'),
          'physicalAccess': physicalAccess,
          'flexibleSchedule': flexibleSchedule,
          'workplaceAdaptation': workplaceAdaptation,
          'assistiveTechnology': assistiveTechnology,
          'elevator': elevator,
          'accessibleParking': accessibleParking,
          'notes': accessibilityDetails.text.trim(),
        },
        'salary': salary.text.trim(),
      });
      if (!mounted) return;
      widget.onPublished?.call();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta publicada correctamente.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nueva oferta laboral', style: TextStyle(fontWeight: FontWeight.w800)),
      leading: Semantics(
        label: 'Volver',
        button: true,
        child: IconButton(tooltip: 'Volver', onPressed: publishing ? null : () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const Text('Información del puesto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
                const SizedBox(height: 6),
                const Text('Completa la información para que las personas puedan conocer mejor la oportunidad.', style: TextStyle(color: _muted, height: 1.4)),
                const SizedBox(height: 18),
                field(title, 'Título del puesto'),
                field(description, 'Descripción del puesto', maxLines: 5),
                field(requiredSkills, 'Habilidades obligatorias (separadas por comas)', maxLines: 3),
                field(preferredSkills, 'Habilidades deseables (separadas por comas)', maxLines: 3),
                field(experience, 'Experiencia requerida en años (0 = sin requisito)', keyboardType: TextInputType.number),
                field(salary, 'Salario o rango salarial (opcional)'),
                field(location, 'Ubicación'),
                dropdown('Área profesional', category, categories, (value) => setState(() => category = value ?? category)),
                dropdown('Modalidad', modality, modalities, (value) => setState(() => modality = value ?? modality)),
                dropdown('Tipo de contrato', contractType, contracts, (value) => setState(() => contractType = value ?? contractType)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8F7FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E0FA))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.accessibility_new_rounded, color: _primary), SizedBox(width: 8), Expanded(child: Text('Accesibilidad de la oferta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)))]),
                      const SizedBox(height: 5),
                      const Text('Selecciona las condiciones de accesibilidad que ofrece el puesto.', style: TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 8),
                      accessibilityTile(title: 'Adaptaciones del puesto', value: workplaceAdaptation, onChanged: (v) => setState(() => workplaceAdaptation = v ?? false)),
                      accessibilityTile(title: 'Tecnología asistiva', value: assistiveTechnology, onChanged: (v) => setState(() => assistiveTechnology = v ?? false)),
                      accessibilityTile(title: 'Horario flexible', value: flexibleSchedule, onChanged: (v) => setState(() => flexibleSchedule = v ?? false)),
                      accessibilityTile(title: 'Acceso físico', value: physicalAccess, onChanged: (v) => setState(() => physicalAccess = v ?? false)),
                      accessibilityTile(title: 'Ascensor', value: elevator, onChanged: (v) => setState(() => elevator = v ?? false)),
                      accessibilityTile(title: 'Estacionamiento accesible', value: accessibleParking, onChanged: (v) => setState(() => accessibleParking = v ?? false)),
                      const SizedBox(height: 4),
                      field(accessibilityDetails, 'Detalles adicionales de accesibilidad (opcional)', maxLines: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))]),
            child: Row(
              children: [
                Expanded(child: Semantics(label: 'Cancelar', button: true, child: OutlinedButton(onPressed: publishing ? null : () => Navigator.pop(context), child: const Text('Cancelar')))),
                const SizedBox(width: 10),
                Expanded(child: Semantics(label: publishing ? 'Publicando oferta' : 'Publicar oferta', button: true, enabled: !publishing, child: FilledButton(onPressed: publishing ? null : publish, style: FilledButton.styleFrom(backgroundColor: _primary), child: publishing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Publicar oferta')))),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
