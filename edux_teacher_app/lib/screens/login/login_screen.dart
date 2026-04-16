/// EduX Teacher App - Login Screen
/// 
/// OPTIMIZED VERSION - Fixed progress dialog with real-time updates,
/// better error handling, and timeout management
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sync_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classes_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/discovery_service.dart';
import '../../services/sync_service.dart';
import '../home/home_screen.dart';
import 'server_discovery_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverIpController = TextEditingController();
  final _serverPortController = TextEditingController(text: '8181');

  bool _obscurePassword = true;
  bool _isDiscovering = false;
  bool _manualEntry = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverIpController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);

    // Listen for auth errors
    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 32),

                // Login Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to mark attendance',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Server Connection
                        _buildServerSection(syncState),
                        const SizedBox(height: 24),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Enter your username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: authState.isLoading ? null : _login,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Help text
                        TextButton.icon(
                          onPressed: _showHelpDialog,
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: const Text('Need help?'),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 56,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'EduX Teacher',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    ).animate().scale().fadeIn();
  }

  Widget _buildServerSection(dynamic syncState) {
    if (_serverIpController.text.isNotEmpty && !_manualEntry) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Connected',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                  ),
                  Text(
                    '${_serverIpController.text}:${_serverPortController.text}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _manualEntry = true),
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Server IP
        TextFormField(
          controller: _serverIpController,
          decoration: InputDecoration(
            labelText: 'Server IP Address',
            hintText: '192.168.1.100',
            prefixIcon: const Icon(Icons.computer),
            suffixIcon: _isDiscovering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Discover Server',
                    onPressed: _discoverServer,
                  ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter server IP';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Server Port
        TextFormField(
          controller: _serverPortController,
          decoration: const InputDecoration(
            labelText: 'Port',
            hintText: '8181',
            prefixIcon: Icon(Icons.settings_ethernet),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Future<void> _discoverServer() async {
    setState(() => _isDiscovering = true);

    final discoveryService = DiscoveryService();
    final servers = await discoveryService.discoverServers(
      timeout: const Duration(seconds: 5),
    );

    setState(() => _isDiscovering = false);

    if (servers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No servers found. Please enter manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      final result = await showDialog<DiscoveredServer>(
        context: context,
        builder: (context) => ServerDiscoveryDialog(servers: servers),
      );

      if (result != null) {
        setState(() {
          _serverIpController.text = result.ipAddress;
          _serverPortController.text = result.port.toString();
          _manualEntry = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _serverIpController.text.trim(),
          int.parse(_serverPortController.text.trim()),
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      // Show loading dialog for data sync with progress tracking
      if (!mounted) return;
      
      final syncResult = await showDialog<FullSyncResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DataSyncDialog(
          syncService: ref.read(syncServiceProvider),
        ),
      );

      if (!mounted) return;

      if (syncResult != null) {
        // Show summary if there were errors
        if (syncResult.errors.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (context) => _SyncWarningDialog(result: syncResult),
          );
        }

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // Sync was cancelled or failed, but allow navigation anyway
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data sync incomplete. You can retry from Settings.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate after delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To connect to your school system:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('1. Make sure your phone is connected to school WiFi'),
            SizedBox(height: 8),
            Text('2. Tap the search icon to find the server automatically'),
            SizedBox(height: 8),
            Text('3. Or ask your admin for the server IP address'),
            SizedBox(height: 8),
            Text('4. Use the same username and password as the desktop app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Data sync dialog with real-time progress updates
class DataSyncDialog extends StatefulWidget {
  final SyncService syncService;

  const DataSyncDialog({
    super.key,
    required this.syncService,
  });

  @override
  State<DataSyncDialog> createState() => _DataSyncDialogState();
}

class _DataSyncDialogState extends State<DataSyncDialog> {
  int _progress = 0;
  String _status = 'Initializing...';
  String? _currentClass;
  bool _isComplete = false;
  bool _hasError = false;
  String _errorMessage = '';
  FullSyncResult? _result;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      final result = await widget.syncService.fetchAllData(
        onProgress: (current, total, status, className) {
          if (mounted) {
            setState(() {
              _progress = current;
              _status = status;
              _currentClass = className;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isComplete = true;
          _result = result;
          _progress = 100;
          _status = result.success ? 'Sync complete!' : 'Sync completed with errors';
        });

        // Auto-close after short delay if successful
        if (result.success && result.errors.isEmpty) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop(result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _status = 'Sync failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isComplete || _hasError,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _isComplete || _hasError ? null : _progress / 100,
                      strokeWidth: 6,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasError
                            ? AppTheme.error
                            : _isComplete
                                ? AppTheme.success
                                : AppTheme.primary,
                      ),
                    ),
                    Center(
                      child: _hasError
                          ? const Icon(
                              Icons.error_outline,
                              color: AppTheme.error,
                              size: 40,
                            )
                          : _isComplete
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.success,
                                  size: 40,
                                )
                              : Text(
                                  '$_progress%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status text
              Text(
                _status,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Current class info
              if (_currentClass != null && !_isComplete && !_hasError)
                Text(
                  _currentClass!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Error message
              if (_hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Result summary
              if (_isComplete && _result != null) ...[
                const SizedBox(height: 16),
                _buildResultSummary(),
              ],

              // Action buttons
              if (_isComplete || _hasError) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_hasError || (_result?.errors.isNotEmpty ?? false))
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Skip for now'),
                      ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_result),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    final result = _result!;
    final totalClasses = result.classes.length;
    final totalStudents = result.studentsByClass.values.fold(
      0,
      (sum, list) => sum + list.length,
    );
    final errorCount = result.errors.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorCount > 0
            ? AppTheme.warning.withValues(alpha: 0.1)
            : AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorCount > 0
              ? AppTheme.warning.withValues(alpha: 0.3)
              : AppTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                errorCount > 0 ? Icons.warning_amber : Icons.check_circle,
                color: errorCount > 0 ? AppTheme.warning : AppTheme.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorCount > 0
                      ? 'Synced with $errorCount issues'
                      : 'All data synced successfully',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: errorCount > 0 ? AppTheme.warning : AppTheme.success,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalClasses classes • $totalStudents students',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Warning dialog shown when some classes failed to sync
class _SyncWarningDialog extends StatelessWidget {
  final dynamic result;

  const _SyncWarningDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.warning),
          const SizedBox(width: 8),
          const Text('Sync Incomplete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Some classes could not be synced:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.errors.entries.map<Widget>((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can retry these classes later from the Sync screen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
