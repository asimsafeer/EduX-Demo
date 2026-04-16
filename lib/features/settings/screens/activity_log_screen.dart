/// EduX School Management System
/// Activity Log Screen - View system activity audit trail
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';
import '../../../services/services.dart';

/// Screen for viewing activity logs
class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  final _scrollController = ScrollController();
  final List<ActivityLog> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 50;

  String? _selectedModule;
  String? _selectedAction;
  DateTimeRange? _dateRange;
  List<String> _availableModules = [];
  List<String> _availableActions = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final service = ActivityLogService.instance();
    _availableModules = await service.getAvailableModules();
    _availableActions = await service.getAvailableActions();
    if (mounted) setState(() {});
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      if (refresh) {
        _offset = 0;
        _logs.clear();
      }

      final service = ActivityLogService.instance();
      final logs = await service.getLogs(
        module: _selectedModule,
        action: _selectedAction,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        limit: _pageSize,
        offset: _offset,
      );

      setState(() {
        _logs.addAll(logs);
        _offset += logs.length;
        _hasMore = logs.length == _pageSize;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadLogs();
    }
  }

  void _applyFilters() {
    _loadLogs(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedModule = null;
      _selectedAction = null;
      _dateRange = null;
    });
    _loadLogs(refresh: true);
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (range != null) {
      setState(() => _dateRange = range);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Filters
          _buildFilters(),

          // Log list
          Expanded(
            child: _logs.isEmpty && !_isLoading
                ? _buildEmptyState()
                : _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Log',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View system activity and audit trail',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _loadLogs(refresh: true),
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasFilters =
        _selectedModule != null ||
        _selectedAction != null ||
        _dateRange != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Module filter
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedModule,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Module',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._availableModules.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      _getModuleDisplayName(m),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedModule = value);
                _applyFilters();
              },
            ),
          ),

          // Action filter
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180, minWidth: 120),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedAction,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Action',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._availableActions.map(
                  (a) => DropdownMenuItem(
                    value: a,
                    child: Text(
                      _getActionDisplayName(a),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedAction = value);
                _applyFilters();
              },
            ),
          ),

          // Date range
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text(
              _dateRange != null
                  ? '${DateFormat.MMMd().format(_dateRange!.start)} - ${DateFormat.MMMd().format(_dateRange!.end)}'
                  : 'Date Range',
            ),
          ),

          // Clear filters
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(LucideIcons.filterX, size: 18),
              label: const Text('Clear'),
            ),

          // Log count
          Text(
            '${_logs.length} entries',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _logs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final log = _logs[index];
        final showDateHeader =
            index == 0 ||
            !_isSameDay(log.createdAt, _logs[index - 1].createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  _formatDateHeader(log.createdAt),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildLogTile(log),
          ],
        );
      },
    );
  }

  Widget _buildLogTile(ActivityLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getActionColor(log.action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActionIcon(log.action),
              color: _getActionColor(log.action),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getModuleDisplayName(log.module),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.actionDisplayName,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getActionColor(log.action),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log.description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Time
          Text(
            DateFormat.jm().format(log.createdAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No activity found',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity will appear here as actions are performed',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMEd().format(date);
    }
  }

  String _getModuleDisplayName(String module) {
    switch (module.toLowerCase()) {
      case 'auth':
        return 'Auth';
      case 'users':
        return 'Users';
      case 'students':
        return 'Students';
      case 'staff':
        return 'Staff';
      case 'attendance':
        return 'Attendance';
      case 'exams':
        return 'Exams';
      case 'fees':
        return 'Fees';
      case 'settings':
        return 'Settings';
      case 'system':
        return 'System';
      default:
        return module;
    }
  }

  String _getActionDisplayName(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return 'Login';
      case 'logout':
        return 'Logout';
      case 'session_restore':
        return 'Session';
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      case 'backup':
        return 'Backup';
      case 'restore':
        return 'Restore';
      default:
        return action;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return LucideIcons.logIn;
      case 'logout':
        return LucideIcons.logOut;
      case 'session_restore':
        return LucideIcons.refreshCw;
      case 'create':
        return LucideIcons.plus;
      case 'update':
        return LucideIcons.edit2;
      case 'delete':
        return LucideIcons.trash2;
      case 'backup':
        return LucideIcons.archive;
      case 'restore':
        return LucideIcons.rotateCcw;
      default:
        return LucideIcons.activity;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
      case 'logout':
      case 'session_restore':
        return AppColors.info;
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.warning;
      case 'delete':
        return AppColors.error;
      case 'backup':
      case 'restore':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}
