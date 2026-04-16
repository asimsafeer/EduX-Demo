/// EduX School Management System
/// User Form Screen - Create/Edit user
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';
import '../../../providers/providers.dart';
import '../../../providers/staff_provider.dart';
import '../../../services/services.dart';
import '../../../services/rbac_service.dart';

/// Screen for creating or editing a user
class UserFormScreen extends ConsumerStatefulWidget {
  /// User ID for editing, null for creating
  final int? userId;

  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingUser = false;
  bool _obscurePassword = true;
  User? _existingUser;
  int? _selectedStaffId;

  // Form controllers
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedRole = 'teacher';

  // Selected permissions
  final Set<String> _selectedPermissions = {};

  bool get isEditing => widget.userId != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (isEditing) {
      _loadUser();
    } else {
      // Initialize with default permissions for the default role (teacher)
      _updatePermissionsForRole(_selectedRole);
    }
  }

  void _updatePermissionsForRole(String role) {
    if (isEditing &&
        _existingUser!.permissions != null &&
        _existingUser!.permissions!.isNotEmpty) {
      // If editing and user has explicit permissions, don't overwrite with defaults
      // Logic handled in _loadUser
      return;
    }

    setState(() {
      _selectedPermissions.clear();
      _selectedPermissions.addAll(
        RbacService.defaultRolePermissions[role] ?? [],
      );
    });
  }

  void _initControllers() {
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoadingUser = true);
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getUserById(widget.userId!);
      if (user != null && mounted) {
        setState(() {
          _existingUser = user;
          _usernameController.text = user.username;
          _fullNameController.text = user.fullName;
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phone ?? '';
          _selectedRole = user.role;

          _selectedPermissions.clear();
          if (user.permissions != null && user.permissions!.isNotEmpty) {
            _selectedPermissions.addAll(user.permissions!.split(','));
          } else {
            // Fallback to role defaults if no explicit permissions
            _selectedPermissions.addAll(
              RbacService.defaultRolePermissions[user.role] ?? [],
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = ref.read(userServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      final permissionsString = _selectedPermissions.join(',');

      if (isEditing) {
        // Update existing user
        await userService.updateUser(
          id: widget.userId!,
          fullName: _fullNameController.text,
          role: _selectedRole,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          permissions: permissionsString,
        );

        // Update username if changed
        if (_usernameController.text != _existingUser?.username) {
          await userService.updateUsername(
            id: widget.userId!,
            newUsername: _usernameController.text,
          );
        }

        await activityLog.logUpdate(
          userId: currentUser?.id,
          module: 'users',
          entityType: 'user',
          entityId: widget.userId!,
          description: 'Updated user "${_fullNameController.text}"',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
        }
      } else {
        // Create new user
        final user = await userService.createUser(
          username: _usernameController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          role: _selectedRole,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          permissions: permissionsString,
          staffId: _selectedStaffId,
        );

        await activityLog.logCreate(
          userId: currentUser?.id,
          module: 'users',
          entityType: 'user',
          entityId: user.id,
          description: 'Created user "${_fullNameController.text}"',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully')),
          );
        }
      }

      // Refresh providers and go back
      ref.invalidate(userListProvider);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account info
                    _buildSectionTitle('Account Information'),
                    const SizedBox(height: 16),
                    _buildUsernameField(),
                    const SizedBox(height: 16),
                    if (!isEditing) ...[
                      _buildPasswordField(),
                      const SizedBox(height: 16),
                    ],
                    // Role Selector
                    _buildRoleSelector(),
                    const SizedBox(height: 32),

                    // Permission Selector (New)
                    _buildPermissionSelector(),
                    const SizedBox(height: 32),

                    // Personal info
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 16),
                    if (!isEditing)
                      _buildStaffSelector()
                    else
                      _buildFullNameField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildEmailField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPhoneField()),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // System admin badge
                    if (isEditing && _existingUser?.isSystemAdmin == true)
                      _buildSystemAdminBadge(),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          _buildActions(),
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
                  isEditing ? 'Edit User' : 'Add User',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isEditing
                      ? 'Update user information'
                      : 'Create a new user account',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        prefixIcon: Icon(LucideIcons.user, size: 20),
        helperText: 'Used for login',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Username is required';
        }
        if (value.length < 3) {
          return 'Username must be at least 3 characters';
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
          return 'Username can only contain letters, numbers, and underscores';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
        helperText: 'At least 6 characters with letters and numbers',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        final authService = ref.read(authServiceProvider);
        return authService.validatePassword(value);
      },
    );
  }

  Widget _buildPermissionSelector() {
    // System admin has all permissions and they cannot be changed
    final isSystemAdmin = _existingUser?.isSystemAdmin ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Permissions', style: AppTextStyles.labelLarge),
            if (!isSystemAdmin)
              TextButton(
                onPressed: () {
                  // Reset to defaults for current role
                  setState(() {
                    _selectedPermissions.clear();
                    _selectedPermissions.addAll(
                      RbacService.defaultRolePermissions[_selectedRole] ?? [],
                    );
                  });
                },
                child: const Text('Reset to Defaults'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isSystemAdmin)
          const Text(
            'System Administrator has full access to all features.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
            ),
            child: Column(
              children: RbacService.allPermissions.entries.map((entry) {
                final permissionKey = entry.key;
                final permissionName = entry.value;
                final isSelected = _selectedPermissions.contains(permissionKey);

                return CheckboxListTile(
                  title: Text(permissionName, style: AppTextStyles.bodyMedium),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPermissions.add(permissionKey);
                      } else {
                        _selectedPermissions.remove(permissionKey);
                      }
                    });
                  },
                  dense: true,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final canChangeRole = !(_existingUser?.isSystemAdmin ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserService.validRoles.map((role) {
            final isSelected = _selectedRole == role;
            return ChoiceChip(
              label: Text(UserService.getRoleDisplayName(role)),
              selected: isSelected,
              onSelected: canChangeRole
                  ? (selected) {
                      if (selected) {
                        setState(() => _selectedRole = role);
                      }
                    }
                  : null,
            );
          }).toList(),
        ),
        if (!canChangeRole)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Role cannot be changed for system administrator',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStaffSelector() {
    final unassignedStaffAsync = ref.watch(unassignedStaffProvider);

    return unassignedStaffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text(
        'Error loading staff: $e',
        style: TextStyle(color: AppColors.error),
      ),
      data: (staffList) {
        if (staffList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No unassigned staff available. Please add a Staff member first.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<int>(
          initialValue: _selectedStaffId,
          decoration: const InputDecoration(
            labelText: 'Select Staff Member',
            prefixIcon: Icon(LucideIcons.users, size: 20),
          ),
          items: staffList.map((staffWithRole) {
            return DropdownMenuItem<int>(
              value: staffWithRole.staff.id,
              child: Text(
                '${staffWithRole.fullName} (${staffWithRole.staff.employeeId})',
              ),
            );
          }).toList(),
          validator: (value) =>
              value == null ? 'Please select a staff member' : null,
          onChanged: (value) {
            setState(() {
              _selectedStaffId = value;
              final selectedStaff = staffList.firstWhere(
                (s) => s.staff.id == value,
              );
              _fullNameController.text = selectedStaff.fullName;
              if (selectedStaff.staff.email != null) {
                _emailController.text = selectedStaff.staff.email!;
              }
              _phoneController.text = selectedStaff.staff.phone;

              // Automatically set role to match staff role if known
              final staffRoleName = selectedStaff.role.name.toLowerCase();
              if (UserService.validRoles.contains(staffRoleName)) {
                _selectedRole = staffRoleName;
                _updatePermissionsForRole(staffRoleName);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      readOnly: isEditing && !(_existingUser?.isSystemAdmin ?? false),
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: const Icon(LucideIcons.userCircle, size: 20),
        helperText: isEditing && !(_existingUser?.isSystemAdmin ?? false)
            ? 'Name is linked to the Staff Profile'
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Full name is required';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email *',
        prefixIcon: Icon(LucideIcons.mail, size: 20),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Invalid email format';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: const InputDecoration(
        labelText: 'Phone (Optional)',
        prefixIcon: Icon(LucideIcons.phone, size: 20),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildSystemAdminBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shield, color: AppColors.info, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Administrator',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This account has full administrative privileges and cannot be deactivated or have its role changed.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _saveUser,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isEditing ? LucideIcons.save : LucideIcons.userPlus,
                    size: 18,
                  ),
            label: Text(isEditing ? 'Save Changes' : 'Create User'),
          ),
        ],
      ),
    );
  }
}
