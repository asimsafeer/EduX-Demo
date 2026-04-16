/// EduX Teacher App - Server Discovery Dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sync_models.dart';

/// Dialog for selecting discovered server
class ServerDiscoveryDialog extends StatelessWidget {
  final List<DiscoveredServer> servers;

  const ServerDiscoveryDialog({
    super.key,
    required this.servers,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Server'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            return _ServerCard(
              server: server,
              onTap: () => Navigator.pop(context, server),
            )
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideX(begin: 0.1, end: 0);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  final DiscoveredServer server;
  final VoidCallback onTap;

  const _ServerCard({
    required this.server,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.computer,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.schoolName ?? server.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.displayUrl,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (server.version != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Version: ${server.version}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
