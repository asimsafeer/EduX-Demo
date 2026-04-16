/// NovaByte Hub — Module Chip Widget
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/module_constants.dart';
import '../theme/app_colors.dart';

/// A chip widget displaying a module name with its icon.
///
/// Supports selected (filled), unselected (outlined), and disabled (locked) states.
class ModuleChip extends StatelessWidget {
  final String moduleId;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final double fontSize;

  const ModuleChip({
    super.key,
    required this.moduleId,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final module = EduXModules.getById(moduleId);
    final name = module?.name ?? moduleId;
    final icon = module?.icon ?? LucideIcons.box;
    final color = module?.color ?? AppColors.textSecondary;

    final effectiveColor = isDisabled
        ? AppColors.textMuted
        : isSelected
        ? color
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveColor.withValues(alpha: isSelected ? 0.5 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDisabled ? LucideIcons.lock : icon,
              size: fontSize + 2,
              color: effectiveColor,
            ),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                color: effectiveColor,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A toggleable module chip for use in selection lists.
class ModuleToggleChip extends StatelessWidget {
  final String moduleId;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const ModuleToggleChip({
    super.key,
    required this.moduleId,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final module = EduXModules.getById(moduleId);
    final name = module?.name ?? moduleId;
    final icon = module?.icon ?? LucideIcons.box;
    final color = module?.color ?? AppColors.primary;

    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
