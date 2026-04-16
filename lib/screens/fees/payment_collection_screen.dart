/// EduX School Management System
/// Payment Collection Screen - Collect fees from students
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/status_extensions.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../repositories/student_repository.dart';

enum StudentSearchMode { search, browse }

class PaymentCollectionScreen extends ConsumerStatefulWidget {
  final int? invoiceId;
  final int? studentId;

  const PaymentCollectionScreen({super.key, this.invoiceId, this.studentId});

  @override
  ConsumerState<PaymentCollectionScreen> createState() =>
      _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState
    extends ConsumerState<PaymentCollectionScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _remarksController = TextEditingController();

  StudentSearchMode _searchMode = StudentSearchMode.search;
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedStudentId;
  int? _selectedInvoiceId;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null) {
      _selectedInvoiceId = widget.invoiceId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(paymentCollectionProvider.notifier)
            .setInvoiceId(widget.invoiceId);
      });
    }

    if (widget.studentId != null) {
      _selectedStudentId = widget.studentId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _chequeNumberController.dispose();
    _bankNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentCollectionProvider);
    final isDesktop = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment'), centerTitle: false),
      body: isDesktop ? _buildDesktopLayout(state) : _buildMobileLayout(state),
    );
  }

  Widget _buildDesktopLayout(PaymentCollectionState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Student Selection
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [if (widget.invoiceId == null) _buildStudentSearch()],
              ),
            ),
          ),
        ),
        // Right Column: Details and Form
        Expanded(
          flex: 7,
          child: state.isProcessing && _selectedInvoiceId == null
              ? const Center(child: AppLoadingIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedInvoiceId != null) ...[
                            _buildInvoiceDetails(_selectedInvoiceId!),
                            const SizedBox(height: 24),
                            _buildPaymentForm(state),
                            const SizedBox(height: 24),
                            _buildPaymentButton(state),
                          ] else if (_selectedStudentId != null)
                            _buildUnpaidInvoices(_selectedStudentId!)
                          else
                            _buildNoSelectionPlaceholder(
                              'Search or select a student to view their pending invoices.',
                            ),
                          if (state.result != null &&
                              state.result!.success) ...[
                            const SizedBox(height: 24),
                            _buildSuccessCard(state.result!),
                          ],
                          if (state.error != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorContainer(state.error!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(PaymentCollectionState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.invoiceId == null) ...[
            _buildStudentSearch(),
            const SizedBox(height: 16),
            if (_selectedStudentId != null) ...[
              _buildUnpaidInvoices(_selectedStudentId!),
              const SizedBox(height: 16),
            ],
          ],
          if (_selectedInvoiceId != null) ...[
            _buildInvoiceDetails(_selectedInvoiceId!),
            const SizedBox(height: 24),
            _buildPaymentForm(state),
            const SizedBox(height: 24),
            _buildPaymentButton(state),
          ],
          if (state.result != null && state.result!.success) ...[
            const SizedBox(height: 24),
            _buildSuccessCard(state.result!),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorContainer(state.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Toggle
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildSearchModeTab(
                'Search by Name/ID',
                StudentSearchMode.search,
              ),
              _buildSearchModeTab('Browse by Class', StudentSearchMode.browse),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Input or Browse UI
        if (_searchMode == StudentSearchMode.search)
          _buildSearchInput()
        else
          _buildBrowseByClass(),
      ],
    );
  }

  Widget _buildSearchModeTab(String title, StudentSearchMode mode) {
    final isSelected = _searchMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _searchMode = mode;
            _selectedStudentId = null;
            _selectedInvoiceId = null;
            _selectedClassId = null;
            _selectedSectionId = null;
          });
          ref.read(paymentCollectionProvider.notifier).reset();
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Student',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Autocomplete<StudentWithEnrollment>(
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<StudentWithEnrollment>.empty();
            }
            // Use repository directly to search across all students
            final repo = ref.read(studentRepositoryProvider);
            try {
              final results = await repo.search(
                StudentFilters(searchQuery: textEditingValue.text, limit: 20),
              );
              return results;
            } catch (e) {
              return const Iterable<StudentWithEnrollment>.empty();
            }
          },
          displayStringForOption: (s) =>
              '${s.student.studentName} ${s.student.fatherName} (${s.student.admissionNumber})',
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Type student name or admission number',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
          onSelected: (student) {
            setState(() {
              _selectedStudentId = student.student.id;
              _selectedInvoiceId = null;
            });
            // Invalidate the unpaid invoices provider to ensure fresh data
            ref.invalidate(studentUnpaidInvoicesProvider(student.student.id));
            ref.read(paymentCollectionProvider.notifier).setStudentId(student.student.id);
          },
        ),
      ],
    );
  }

  Widget _buildBrowseByClass() {
    final classesAsync = ref.watch(classesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Class Dropdown
            Expanded(
              child: classesAsync.when(
                data: (classes) => DropdownButtonFormField<int>(
                  key: ValueKey(_selectedClassId),
                  initialValue: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                      _selectedSectionId = null; // Reset section
                      _selectedStudentId = null; // Reset student
                    });
                  },
                ),
                loading: () => const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text('Error loading classes'),
              ),
            ),
            const SizedBox(width: 16),
            // Section Dropdown
            Expanded(
              child: _selectedClassId == null
                  ? const SizedBox.shrink()
                  : Consumer(
                      builder: (context, ref, child) {
                        final sectionsAsync = ref.watch(
                          sectionsByClassProvider(_selectedClassId!),
                        );
                        return sectionsAsync.when(
                          data: (sections) => DropdownButtonFormField<int>(
                            key: ValueKey(_selectedSectionId),
                            initialValue: _selectedSectionId,
                            decoration: InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            items: sections
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSectionId = value;
                                _selectedStudentId = null; // Reset student
                              });
                            },
                          ),
                          loading: () => const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (_, __) =>
                              const Text('Error loading sections'),
                        );
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedClassId != null && _selectedSectionId != null)
          _buildStudentList(_selectedClassId!, _selectedSectionId!),
      ],
    );
  }

  Widget _buildStudentList(int classId, int sectionId) {
    // Need a provider to get students by class/section.
    // Using a FutureBuilder here for simplicity as we don't have a specific family provider for this in student_provider yet
    // that doesn't involve global filters.

    return FutureBuilder<List<StudentWithEnrollment>>(
      future: ref
          .read(studentRepositoryProvider)
          .getByClassSection(classId, sectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator());
        }

        if (snapshot.hasError) {
          return AppErrorState(message: snapshot.error.toString());
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return Center(
            child: Text(
              'No students found in this section.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          );
        }

        // Sort by Roll Number (assuming getByClassSection might sort by name)
        // Check local sorting just in case repository sort isn't enough or different
        // The repository method getByClassSection sorts by studentName.
        // Let's re-sort by roll number locally for display if available
        students.sort((a, b) {
          final rollA =
              int.tryParse(a.currentEnrollment?.rollNumber ?? '') ?? 999999;
          final rollB =
              int.tryParse(b.currentEnrollment?.rollNumber ?? '') ?? 999999;
          return rollA.compareTo(rollB);
        });

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final isSelected = _selectedStudentId == student.student.id;

              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context).colorScheme.primary,
                textColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
                iconColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    student.student.studentName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  student.student.studentName,
                  style: isSelected
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text(
                  'Roll No: ${student.currentEnrollment?.rollNumber ?? '-'} • ${student.student.fatherName ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStudentId = student.student.id;
                    _selectedInvoiceId = null;
                  });
                  // Invalidate the unpaid invoices provider to ensure fresh data
                  ref.invalidate(studentUnpaidInvoicesProvider(student.student.id));
                  ref.read(paymentCollectionProvider.notifier).setStudentId(student.student.id);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUnpaidInvoices(int studentId) {
    final asyncInvoices = ref.watch(studentUnpaidInvoicesProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Invoices',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            // Refresh button to manually reload invoices
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                ref.invalidate(studentUnpaidInvoicesProvider(studentId));
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        asyncInvoices.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, stack) {
            debugPrint('Error loading unpaid invoices: $e\n$stack');
            return AppErrorState(
              message: 'Error loading invoices: $e',
              onRetry: () {
                ref.invalidate(studentUnpaidInvoicesProvider(studentId));
              },
            );
          },
          data: (invoices) {
            if (invoices.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'No pending invoices',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final isSelected = _selectedInvoiceId == invoice.id;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.2)
                            : invoice.status.invoiceStatusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        invoice.status.invoiceStatusIcon,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : invoice.status.invoiceStatusColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      _formatMonth(invoice.month),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Due: ${DateFormat('dd MMM').format(invoice.dueDate)} • ${invoice.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.8)
                            : invoice.status.invoiceStatusTextColor,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(invoice.balanceAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() => _selectedInvoiceId = invoice.id);
                      ref
                          .read(paymentCollectionProvider.notifier)
                          .setInvoiceId(invoice.id);
                      _amountController.text = invoice.balanceAmount
                          .toStringAsFixed(0);
                      ref
                          .read(paymentCollectionProvider.notifier)
                          .setAmount(invoice.balanceAmount);
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInvoiceDetails(int invoiceId) {
    final asyncInvoice = ref.watch(invoiceByIdProvider(invoiceId));

    return asyncInvoice.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (invoice) {
        if (invoice == null) {
          return const Text('Invoice not found');
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Student info header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        invoice.studentName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${invoice.student.admissionNumber} • ${invoice.classSection}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: invoice.invoice.status.invoiceStatusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        invoice.invoice.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: invoice.invoice.status.invoiceStatusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Invoice details
                _buildDetailRow('Invoice No', invoice.invoice.invoiceNumber),
                _buildDetailRow('Month', _formatMonth(invoice.invoice.month)),
                _buildDetailRow(
                  'Due Date',
                  DateFormat('dd MMM yyyy').format(invoice.invoice.dueDate),
                ),
                const Divider(height: 16),

                // Amount details
                _buildDetailRow(
                  'Total Amount',
                  _currencyFormat.format(invoice.invoice.netAmount),
                ),
                _buildDetailRow(
                  'Paid Amount',
                  _currencyFormat.format(invoice.invoice.paidAmount),
                  valueColor: Colors.green,
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  'Balance Due',
                  _currencyFormat.format(invoice.invoice.balanceAmount),
                  valueColor: Colors.red,
                  isBold: true,
                ),

                // Fee breakdown
                if (invoice.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text(
                      'Fee Breakdown',
                      style: TextStyle(fontSize: 14),
                    ),
                    children: invoice.items
                        .map(
                          (item) => ListTile(
                            dense: true,
                            title: Text(
                              item.feeType.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Text(
                              _currencyFormat.format(item.item.netAmount),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(PaymentCollectionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payment,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),

        layoutGrid(
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                ref.read(paymentCollectionProvider.notifier).setAmount(amount);
              },
            ),

            // Payment mode
            DropdownButtonFormField<String>(
              key: ValueKey(state.paymentMode),
              initialValue: state.paymentMode,
              decoration: InputDecoration(
                labelText: 'Payment Mode *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: FeeConstants.paymentModes
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(FeeConstants.getPaymentModeDisplayName(mode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(paymentCollectionProvider.notifier)
                      .setPaymentMode(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mode-specific fields
        if (state.paymentMode == FeeConstants.paymentModeCheque) ...[
          layoutGrid(
            children: [
              TextFormField(
                controller: _chequeNumberController,
                decoration: InputDecoration(
                  labelText: 'Cheque Number *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(paymentCollectionProvider.notifier)
                      .setChequeNumber(value);
                },
              ),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(paymentCollectionProvider.notifier)
                      .setBankName(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectChequeDate(state),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Cheque Date *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                state.chequeDate != null
                    ? DateFormat('dd MMM yyyy').format(state.chequeDate!)
                    : 'Select date',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (state.paymentMode == FeeConstants.paymentModeBank ||
            state.paymentMode == FeeConstants.paymentModeOnline) ...[
          TextFormField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: 'Reference Number *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              ref
                  .read(paymentCollectionProvider.notifier)
                  .setReferenceNumber(value);
            },
          ),
          const SizedBox(height: 16),
        ],

        // Remarks (optional)
        TextFormField(
          controller: _remarksController,
          decoration: InputDecoration(
            labelText: 'Remarks (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
          onChanged: (value) {
            ref.read(paymentCollectionProvider.notifier).setRemarks(value);
          },
        ),
      ],
    );
  }

  /// Helper to create a responsive grid: 2 columns on desktop, 1 on mobile
  Widget layoutGrid({required List<Widget> children}) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    if (!isDesktop) {
      return Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand((w) => [Expanded(child: w), const SizedBox(width: 16)])
              .toList()
            ..removeLast(),
    );
  }

  Future<void> _selectChequeDate(PaymentCollectionState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate: state.chequeDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      ref.read(paymentCollectionProvider.notifier).setChequeDate(date);
    }
  }

  Widget _buildPaymentButton(PaymentCollectionState state) {
    // Check if selected invoice is fully paid
    final isInvoicePaid =
        _selectedInvoiceId != null &&
        (ref
                    .read(invoiceByIdProvider(_selectedInvoiceId!))
                    .asData
                    ?.value
                    ?.invoice
                    .status ??
                '') ==
            FeeConstants.invoiceStatusPaid;

    final isBalanceZero =
        _selectedInvoiceId != null &&
        (ref
                    .read(invoiceByIdProvider(_selectedInvoiceId!))
                    .asData
                    ?.value
                    ?.invoice
                    .balanceAmount ??
                0) <=
            0;

    final isDisabled =
        state.isProcessing || !state.isValid || isInvoicePaid || isBalanceZero;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _collectPayment(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment),
                  const SizedBox(width: 8),
                  Text(
                    'Collect ${_currencyFormat.format(state.amount)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessCard(dynamic result) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 2),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Collected!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Receipt No', result.receiptNumber),
            _buildDetailRow(
              'Amount Paid',
              _currencyFormat.format(result.amount),
              valueColor: Colors.green,
              isBold: true,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _printReceipt(result.paymentId),
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(paymentCollectionProvider.notifier).reset();
                    setState(() {
                      _selectedStudentId = null;
                      _selectedInvoiceId = null;
                      _amountController.clear();
                      _referenceController.clear();
                      _chequeNumberController.clear();
                      _bankNameController.clear();
                      _remarksController.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Payment'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMMM yyyy').format(date);
      }
    } catch (_) {}
    return month;
  }

  Future<void> _collectPayment() async {
    final success = await ref.read(paymentCollectionProvider.notifier).collectPayment();
    if (success && mounted) {
      // Force refresh the unpaid invoices list after successful payment
      if (_selectedStudentId != null) {
        ref.invalidate(studentUnpaidInvoicesProvider(_selectedStudentId!));
      }
    }
  }

  Future<void> _printReceipt(int paymentId) async {
    try {
      final service = ref.read(receiptServiceProvider);
      await service.printReceiptByPaymentId(context, paymentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
