import 'package:flutter/material.dart';
import 'services/api_service.dart';

class DeleteAccountPage extends StatefulWidget {
  final String token;
  final ApiService api;
  final Future<void> Function()? onDeleted;

  const DeleteAccountPage({
    super.key,
    required this.token,
    required this.api,
    this.onDeleted,
  });

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final response = await widget.api.deleteAccount(widget.token, _password.text);
      if (!mounted) return;
      await widget.onDeleted?.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'Tu cuenta fue eliminada.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar mi cuenta'),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 30),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Eliminar mi cuenta',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Esta acción es permanente. Se eliminará tu cuenta y los datos asociados de INKU, incluidas las postulaciones y conversaciones relacionadas.',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').isEmpty ? 'Ingresa tu contraseña.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmation,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Escribe ELIMINAR para confirmar',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim() == 'ELIMINAR'
                      ? null
                      : 'Escribe ELIMINAR exactamente.',
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _deleteAccount,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text(_submitting ? 'Eliminando…' : 'Eliminar cuenta'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
