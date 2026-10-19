import 'package:flutter/material.dart';
import 'services/api_service.dart';

const _notificationsPrimary = Color(0xFF4F46E5);
const _notificationsInk = Color(0xFF111827);
const _notificationsMuted = Color(0xFF64748B);
const _notificationsLine = Color(0xFFE2E8F0);

class NotificationsPage extends StatefulWidget {
  final String token;
  final ApiService api;

  const NotificationsPage({
    super.key,
    required this.token,
    required this.api,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> items = [];
  final Set<String> selectedIds = <String>{};
  bool loading = true;
  bool deleting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await widget.api.notifications(widget.token);
      if (!mounted) return;
      setState(() {
        items = response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        selectedIds.clear();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> markAsRead(int index) async {
    final id = items[index]['id']?.toString() ?? '';
    if (id.isEmpty || items[index]['read'] == true || selectedIds.isNotEmpty) return;
    try {
      await widget.api.markNotificationRead(widget.token, id);
      if (!mounted) return;
      setState(() => items[index]['read'] = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void toggleSelectAll() {
    final ids = items
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    setState(() {
      if (selectedIds.length == ids.length && ids.isNotEmpty) {
        selectedIds.clear();
      } else {
        selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> confirmDelete({String? id}) async {
    final ids = id != null ? <String>[id] : selectedIds.toList();
    if (ids.isEmpty || deleting) return;

    final multiple = ids.length > 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(multiple ? '¿Eliminar notificaciones?' : '¿Eliminar notificación?'),
        content: Text(
          multiple
              ? 'Se eliminarán ${ids.length} notificaciones seleccionadas. Esta acción no se puede deshacer.'
              : 'Esta notificación se eliminará de tu cuenta. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => deleting = true);
    try {
      if (ids.length == 1) {
        await widget.api.deleteNotification(widget.token, ids.first);
      } else {
        await widget.api.deleteNotifications(widget.token, ids);
      }
      if (!mounted) return;
      setState(() {
        items.removeWhere((item) => ids.contains(item['id']?.toString()));
        selectedIds.removeAll(ids);
        deleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ids.length == 1 ? 'Notificación eliminada.' : '${ids.length} notificaciones eliminadas.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget notificationCard(Map<String, dynamic> item, int index) {
    final read = item['read'] == true;
    final id = item['id']?.toString() ?? '';
    final selected = id.isNotEmpty && selectedIds.contains(id);
    final title = item['title']?.toString().trim().isNotEmpty == true
        ? item['title'].toString()
        : 'Notificación';
    final message = item['message']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: selected
          ? const Color(0xFFEDE9FE)
          : read
              ? Colors.white
              : const Color(0xFFF5F3FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? _notificationsPrimary
              : read
                  ? _notificationsLine
                  : const Color(0xFFDCD6FF),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (selectedIds.isNotEmpty) {
            if (id.isNotEmpty) toggleSelection(id);
          } else {
            markAsRead(index);
          }
        },
        onLongPress: id.isEmpty ? null : () => toggleSelection(id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedIds.isNotEmpty || selected)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Checkbox(
                    value: selected,
                    activeColor: _notificationsPrimary,
                    onChanged: id.isEmpty ? null : (_) => toggleSelection(id),
                  ),
                ),
              CircleAvatar(
                backgroundColor: read ? const Color(0xFFF1F5F9) : const Color(0xFFE7E2FF),
                child: Icon(
                  read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                  color: read ? _notificationsMuted : _notificationsPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                              color: _notificationsInk,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: _notificationsPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Eliminar',
                          visualDensity: VisualDensity.compact,
                          onPressed: id.isEmpty || deleting ? null : () => confirmDelete(id: id),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(message, style: const TextStyle(color: _notificationsMuted, height: 1.4)),
                    ],
                    if (!read) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Toca para marcar como leída',
                        style: TextStyle(fontSize: 12, color: _notificationsPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = items.where((item) => item['read'] != true).length;
    final allSelected = items.isNotEmpty && selectedIds.length == items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: allSelected ? 'Deseleccionar todas' : 'Seleccionar todas',
              onPressed: deleting ? null : toggleSelectAll,
              icon: Icon(allSelected ? Icons.deselect_rounded : Icons.checklist_rounded),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: loading || deleting ? null : loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: _notificationsPrimary))
            : RefreshIndicator(
                onRefresh: loadNotifications,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Tus notificaciones',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _notificationsInk),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E2FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unreadCount ${unreadCount == 1 ? 'nueva' : 'nuevas'}',
                              style: const TextStyle(
                                color: _notificationsPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Aquí encontrarás novedades relacionadas con tu actividad en INKLU.',
                      style: TextStyle(color: _notificationsMuted, height: 1.4),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: _notificationsPrimary),
                          SizedBox(width: 7),
                          Text(
                            'Las nuevas notificaciones están resaltadas.',
                            style: TextStyle(fontSize: 12, color: _notificationsMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (selectedIds.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _notificationsLine),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${selectedIds.length} seleccionada${selectedIds.length == 1 ? '' : 's'}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: _notificationsInk),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: deleting ? null : () => confirmDelete(),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF3C7C7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No pudimos cargar tus notificaciones.', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(error!, style: const TextStyle(color: _notificationsMuted)),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: loadNotifications,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Intentar nuevamente'),
                            ),
                          ],
                        ),
                      )
                    else if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 46),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _notificationsLine),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 54, color: _notificationsMuted),
                            SizedBox(height: 14),
                            Text('Todavía no tienes notificaciones.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _notificationsInk)),
                            SizedBox(height: 6),
                            Text('Cuando haya novedades, aparecerán aquí.', textAlign: TextAlign.center, style: TextStyle(color: _notificationsMuted, height: 1.4)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(items.length, (index) => notificationCard(items[index], index)),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: OutlinedButton.icon(
            onPressed: deleting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              foregroundColor: _notificationsPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
