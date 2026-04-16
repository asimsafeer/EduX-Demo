/// EduX School Management System
/// Global Keyboard Shortcuts Handler
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

/// Keyboard shortcut action
typedef ShortcutAction = VoidCallback;

/// Keyboard shortcut definition
class AppShortcut {
  final SingleActivator activator;
  final String description;
  final ShortcutAction action;

  const AppShortcut({
    required this.activator,
    required this.description,
    required this.action,
  });
}

/// Global keyboard shortcuts handler widget
class KeyboardShortcutsHandler extends StatefulWidget {
  final Widget child;
  final List<AppShortcut>? additionalShortcuts;

  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
    this.additionalShortcuts,
  });

  @override
  State<KeyboardShortcutsHandler> createState() =>
      _KeyboardShortcutsHandlerState();
}

class _KeyboardShortcutsHandlerState extends State<KeyboardShortcutsHandler> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _buildShortcuts(context),
      child: Actions(
        actions: _buildActions(context),
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }

  Map<ShortcutActivator, Intent> _buildShortcuts(BuildContext context) {
    return {
      // Navigation shortcuts
      const SingleActivator(LogicalKeyboardKey.keyD, control: true):
          const _NavigateIntent(AppRoutes.dashboard),
      const SingleActivator(
        LogicalKeyboardKey.keyS,
        control: true,
        shift: true,
      ): const _NavigateIntent(
        AppRoutes.students,
      ),
      const SingleActivator(
        LogicalKeyboardKey.keyE,
        control: true,
        shift: true,
      ): const _NavigateIntent(
        AppRoutes.staff,
      ),
      const SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
        shift: true,
      ): const _NavigateIntent(
        AppRoutes.attendance,
      ),
      const SingleActivator(
        LogicalKeyboardKey.keyF,
        control: true,
        shift: true,
      ): const _NavigateIntent(
        AppRoutes.fees,
      ),
      const SingleActivator(
        LogicalKeyboardKey.keyX,
        control: true,
        shift: true,
      ): const _NavigateIntent(
        AppRoutes.exams,
      ),
      const SingleActivator(LogicalKeyboardKey.comma, control: true):
          const _NavigateIntent(AppRoutes.settings),

      // Action shortcuts
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const _NewItemIntent(),
      const SingleActivator(LogicalKeyboardKey.keyP, control: true):
          const _PrintIntent(),
      const SingleActivator(LogicalKeyboardKey.f5): const _RefreshIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const _CloseIntent(),

      // Help
      const SingleActivator(LogicalKeyboardKey.f1): const _HelpIntent(),
    };
  }

  Map<Type, Action<Intent>> _buildActions(BuildContext context) {
    return {
      _NavigateIntent: CallbackAction<_NavigateIntent>(
        onInvoke: (intent) {
          context.go(intent.route);
          return null;
        },
      ),
      _NewItemIntent: CallbackAction<_NewItemIntent>(
        onInvoke: (intent) {
          // Trigger contextual new item action based on current route
          _handleNewItem(context);
          return null;
        },
      ),
      _PrintIntent: CallbackAction<_PrintIntent>(
        onInvoke: (intent) {
          // Print current view if applicable
          debugPrint('Print shortcut triggered');
          return null;
        },
      ),
      _RefreshIntent: CallbackAction<_RefreshIntent>(
        onInvoke: (intent) {
          // Trigger refresh on current view
          debugPrint('Refresh shortcut triggered');
          return null;
        },
      ),
      _CloseIntent: CallbackAction<_CloseIntent>(
        onInvoke: (intent) {
          // Close dialogs/modals or go back
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          return null;
        },
      ),
      _HelpIntent: CallbackAction<_HelpIntent>(
        onInvoke: (intent) {
          _showShortcutsHelp(context);
          return null;
        },
      ),
    };
  }

  void _handleNewItem(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/students')) {
      context.go('/students/new');
    } else if (location.startsWith('/staff')) {
      context.go('/staff/new');
    } else if (location.startsWith('/exams')) {
      context.go('/exams/new');
    } else if (location.startsWith('/fees/invoices')) {
      context.go('/fees/invoices/generate');
    }
  }

  void _showShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.keyboard, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Keyboard Shortcuts'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shortcutRow('Ctrl+D', 'Go to Dashboard'),
              _shortcutRow('Ctrl+Shift+S', 'Go to Students'),
              _shortcutRow('Ctrl+Shift+E', 'Go to Staff'),
              _shortcutRow('Ctrl+Shift+A', 'Go to Attendance'),
              _shortcutRow('Ctrl+Shift+F', 'Go to Fees'),
              _shortcutRow('Ctrl+Shift+X', 'Go to Exams'),
              _shortcutRow('Ctrl+,', 'Open Settings'),
              const Divider(height: 24),
              _shortcutRow('Ctrl+N', 'New Item'),
              _shortcutRow('Ctrl+P', 'Print'),
              _shortcutRow('F5', 'Refresh'),
              _shortcutRow('Escape', 'Close/Back'),
              _shortcutRow('F1', 'Show Help'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _shortcutRow(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description),
        ],
      ),
    );
  }
}

// Intent classes
class _NavigateIntent extends Intent {
  final String route;
  const _NavigateIntent(this.route);
}

class _NewItemIntent extends Intent {
  const _NewItemIntent();
}

class _PrintIntent extends Intent {
  const _PrintIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}

class _HelpIntent extends Intent {
  const _HelpIntent();
}
