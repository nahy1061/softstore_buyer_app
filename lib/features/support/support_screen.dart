import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/message_service.dart';
import 'ticket_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _svc = MessageService();
  List<SupportTicket> _tickets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tickets = await _svc.tickets();
      setState(() { _tickets = tickets; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _newTicket() => _showNewTicketSheet();

  Future<void> _showNewTicketSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTicketSheet(svc: _svc),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Support'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _newTicket),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _tickets.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No support tickets', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(onPressed: _newTicket, icon: const Icon(Icons.add), label: const Text('New Ticket')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brandOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) {
                      final t = _tickets[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketChatScreen(ticketId: t.id, subject: t.subject))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.brandOrange.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.support_agent_outlined, color: AppColors.brandOrange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('#${t.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (t.status == 'open' ? AppColors.success : Colors.grey).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t.status.toUpperCase(), style: TextStyle(color: t.status == 'open' ? AppColors.success : Colors.grey, fontWeight: FontWeight.w700, fontSize: 10)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _tickets.isNotEmpty ? FloatingActionButton(
        onPressed: _newTicket,
        backgroundColor: AppColors.brandOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}

class _NewTicketSheet extends StatefulWidget {
  final MessageService svc;
  const _NewTicketSheet({required this.svc});
  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _subjectCtrl.dispose(); _messageCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.svc.createTicket(_subjectCtrl.text.trim(), _messageCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('New Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _subjectCtrl, decoration: const InputDecoration(hintText: 'Subject')),
        const SizedBox(height: 10),
        TextField(controller: _messageCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe your issue...')),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.brandOrange),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
