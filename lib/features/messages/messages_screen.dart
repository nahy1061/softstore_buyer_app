import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/session_store.dart';
import '../../core/networking/api_error.dart';
import '../../services/message_service.dart';
import '../auth/auth_flow_view.dart';
import 'store_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _svc = MessageService();
  List<ConversationThread> _threads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (SessionStore.instance.isSignedIn) {
      _loadInbox();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadInbox() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final threads = await _svc.fetchInbox();
      if (mounted) setState(() => _threads = threads);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load messages.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!SessionStore.instance.isSignedIn) {
      return _buildSignInPrompt(context);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_threads.isEmpty) {
      return _buildEmpty(context);
    }
    return RefreshIndicator(
      onRefresh: _loadInbox,
      color: AppColors.brandOrange,
      child: ListView.separated(
        itemCount: _threads.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Theme.of(context).dividerColor),
        itemBuilder: (_, i) => _ThreadTile(
          thread: _threads[i],
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(
                builder: (_) => StoreChatScreen(
                  conversationPath: _threads[i].conversationPath,
                  storeName: _threads[i].storeName,
                ),
              ))
              .then((_) => _loadInbox()),
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Sign in to view messages',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () async {
                await AuthFlowView.showAuthSheet(context,
                    contextMessage: 'Sign in to view your messages.');
                if (mounted && SessionStore.instance.isSignedIn) {
                  _loadInbox();
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No conversations yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Message a seller from any product page.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadInbox,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thread list tile
// ---------------------------------------------------------------------------

class _ThreadTile extends StatelessWidget {
  final ConversationThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.brandOrange.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _initial(thread.storeName),
            style: const TextStyle(
              color: AppColors.brandOrange,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.storeName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: thread.hasUnread
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (thread.date.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              thread.date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              thread.lastMessage.isEmpty
                  ? 'Tap to view conversation'
                  : thread.lastMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: thread.hasUnread
                    ? theme.colorScheme.onSurface.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: thread.hasUnread ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (thread.hasUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.brandOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
