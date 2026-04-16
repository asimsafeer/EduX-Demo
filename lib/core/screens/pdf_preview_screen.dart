/// EduX School Management System
/// PDF Preview Screen - Visual preview for generated PDFs
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../utils/pdf_helper.dart';
import '../theme/theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String documentName;
  final VoidCallback? onExportExcel;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.documentName,
    this.onExportExcel,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final TransformationController _transformController =
      TransformationController();
  double _currentZoom = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 4.0;
  static const double _zoomStep = 0.25;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + _zoomStep).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - _zoomStep).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  void _setZoom(double zoom) {
    setState(() => _currentZoom = zoom);
    _transformController.value = Matrix4.identity()..scaleByVector3(Vector3(zoom, zoom, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final isMedium = screenWidth >= 600 && screenWidth < 1024;

    final double maxPageWidth;
    if (isCompact) {
      maxPageWidth = screenWidth * 0.95;
    } else if (isMedium) {
      maxPageWidth = screenWidth * 0.85;
    } else {
      maxPageWidth = 700;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName,
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 1,
        actions: [
          // Zoom controls
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildZoomButton(
                  icon: LucideIcons.zoomOut,
                  onTap: _currentZoom > _minZoom ? _zoomOut : null,
                  tooltip: 'Zoom Out',
                ),
                InkWell(
                  onTap: _resetZoom,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      '${(_currentZoom * 100).round()}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _buildZoomButton(
                  icon: LucideIcons.zoomIn,
                  onTap: _currentZoom < _maxZoom ? _zoomIn : null,
                  tooltip: 'Zoom In',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          if (widget.onExportExcel != null)
            IconButton(
              icon: const Icon(Icons.table_view, color: Colors.green),
              onPressed: widget.onExportExcel,
              tooltip: 'Export to Excel',
            ),
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: () async {
              final success = await PdfHelper.savePdf(
                widget.pdfBytes,
                widget.documentName,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'PDF saved successfully' : 'Failed to save PDF',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Save PDF',
          ),
          IconButton(
            icon: const Icon(LucideIcons.printer),
            onPressed: () async {
              await PdfHelper.safePrint(widget.pdfBytes, widget.documentName);
            },
            tooltip: 'Print PDF',
          ),
          // Share button - visible with primary color
          IconButton(
            icon: Icon(LucideIcons.share2, color: AppColors.primary),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: widget.pdfBytes,
                filename: '${widget.documentName}.pdf',
              );
            },
            tooltip: 'Share PDF',
          ),
          const SizedBox(width: 4),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF0F2F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveMaxWidth = maxPageWidth.clamp(
            300.0,
            constraints.maxWidth - (isCompact ? 8 : 32),
          );

          return InteractiveViewer(
            transformationController: _transformController,
            minScale: _minZoom,
            maxScale: _maxZoom,
            onInteractionEnd: (details) {
              // Sync zoom level display with gesture zoom
              final scale = _transformController.value.getMaxScaleOnAxis();
              if (scale != _currentZoom) {
                setState(() => _currentZoom = scale);
              }
            },
            child: PdfPreview(
              build: (format) async => widget.pdfBytes,
              pdfFileName: '${widget.documentName}.pdf',
              canDebug: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              initialPageFormat: PdfPageFormat.a4,
              allowPrinting: false,
              allowSharing: false,
              maxPageWidth: effectiveMaxWidth,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 16,
                vertical: isCompact ? 8 : 16,
              ),
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading preview...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: onTap != null
            ? AppColors.textPrimary
            : AppColors.textSecondary.withValues(alpha: 0.4),
      ),
    );
  }
}
