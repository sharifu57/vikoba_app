import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import 'package:vikoba_app/app/constants/app_colors.dart';
import 'member_controller.dart';

class MemberSharePurchasePage extends StatefulWidget {
  const MemberSharePurchasePage({super.key});

  @override
  State<MemberSharePurchasePage> createState() =>
      _MemberSharePurchasePageState();
}

class _MemberSharePurchasePageState extends State<MemberSharePurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isSubmitting = false;
  String? _proofFilePath;
  String? _proofFileName;

  MemberController get _controller => Get.find<MemberController>();

  double get _sharePrice => _number(
    _controller.shareSummary['unitPrice'] ??
        _controller.shareSummary['sharePrice'],
  );

  double get _requestedQuantity {
    final amount =
        (double.tryParse(_amountController.text.trim()) ?? 0) -
        _configuredJamiiAmount;
    if (_sharePrice <= 0) return 0;
    return amount > 0 ? amount / _sharePrice : 0;
  }

  double get _configuredJamiiAmount =>
      _number(_controller.shareSummary['jamiiContributionPerSharePayment']);

  @override
  void dispose() {
    _amountController.dispose();
    _paymentReferenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final amount = double.parse(_amountController.text.trim());
    final quantity = _requestedQuantity;
    if (_configuredJamiiAmount <= 0) {
      Get.snackbar(
        'Jamii is not configured',
        'Ask your group admin to configure the Jamii amount first.',
      );
      return;
    }
    if (_proofFilePath == null) {
      Get.snackbar('Proof required', 'Attach a receipt or payment screenshot.');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      await _controller.submitSharePurchaseProof(
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentReference: _paymentReferenceController.text.trim(),
        proofText: _noteController.text.trim(),
        proofFilePath: _proofFilePath,
        jamiiAmount: _configuredJamiiAmount,
      );
      if (!mounted) return;
      Get.snackbar(
        'Proof submitted for review',
        '${quantity.toStringAsFixed(8)} shares await accountant and chair approval.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      Get.offAllNamed('/member');
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Purchase failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickProofFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      final file = files.isEmpty ? null : files.first;
      if (file?.path != null && mounted) {
        setState(() {
          _proofFilePath = file!.path;
          _proofFileName = file.name;
        });
      }
    } on MissingPluginException {
      if (!mounted) return;
      Get.snackbar(
        'File picker unavailable',
        'Please completely stop and rebuild the app before attaching a proof file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Could not select proof',
        error.message ?? 'The file picker could not open.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy shares'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group share settings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'One share: ${_controller.currency.value} ${_sharePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Total payment amount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'TZS ',
                    hintText: '50000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid number';
                    }
                    if (_sharePrice <= 0) {
                      return 'Share price is not configured';
                    }
                    if (_configuredJamiiAmount <= 0) {
                      return 'Ask your group admin to configure Jamii first';
                    }
                    if (amount <= _configuredJamiiAmount) {
                      return 'Total payment must be greater than Jamii';
                    }
                    final minimum = _number(
                      _controller.shareSummary['minimumSharePurchaseAmount'],
                    );
                    if (amount - _configuredJamiiAmount < minimum) {
                      return 'Share amount after Jamii is below the minimum';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 18.h),
                Text(
                  'Jamii amount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  initialValue: _configuredJamiiAmount > 0
                      ? _configuredJamiiAmount.toStringAsFixed(2)
                      : '',
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixText: '${_controller.currency.value} ',
                    hintText: 'Ask admin to configure Jamii',
                    helperText:
                        'Deducted from the total payment before calculating shares.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Payment method',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  items: const ['Cash', 'Mobile Money', 'Bank Transfer']
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                ),
                if (_requestedQuantity > 0) ...[
                  SizedBox(height: 10.h),
                  Text(
                    '${_controller.currency.value} ${_configuredJamiiAmount.toStringAsFixed(2)} Jamii + ${_controller.currency.value} ${((double.tryParse(_amountController.text.trim()) ?? 0) - _configuredJamiiAmount).toStringAsFixed(2)} shares = ${_requestedQuantity.toStringAsFixed(8)} shares',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(height: 18.h),
                Text(
                  'M-Pesa reference or receipt number',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _paymentReferenceController,
                  decoration: InputDecoration(
                    hintText: 'e.g. QWE123ABC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Proof details',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Paste the SMS confirmation or describe the payment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickProofFile,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(_proofFileName ?? 'Attach receipt or screenshot'),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitPurchase,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting proof...'
                          : 'Submit for approval',
                    ),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class MemberContributionPage extends StatefulWidget {
  const MemberContributionPage({super.key});

  @override
  State<MemberContributionPage> createState() => _MemberContributionPageState();
}

class _MemberContributionPageState extends State<MemberContributionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String _type = 'Regular contribution';

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add contribution')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contribution type',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children:
                    [
                          'Regular contribution',
                          'Emergency fund',
                          'Special contribution',
                        ]
                        .map(
                          (option) => ChoiceChip(
                            label: Text(option),
                            selected: _type == option,
                            onSelected: (_) => setState(() => _type = option),
                            selectedColor: AppColors.primary.withValues(
                              alpha: .12,
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        )
                        .toList(),
              ),
              SizedBox(height: 18.h),
              Text(
                'Amount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'TZS ',
                  hintText: '200000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contribution amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18.h),
              Text(
                'Date',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _dateController.text = picked.toLocal().toString().split(
                      ' ',
                    )[0];
                  }
                },
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Get.snackbar(
                        'Contribution not submitted',
                        'Contribution submission is not available until an active contribution period is selected.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text('Save contribution'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberLoanRequestPage extends StatefulWidget {
  const MemberLoanRequestPage({super.key});

  @override
  State<MemberLoanRequestPage> createState() => _MemberLoanRequestPageState();
}

class _MemberLoanRequestPageState extends State<MemberLoanRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customPurposeController = TextEditingController();
  final Set<int> _guarantors = <int>{};
  final Map<int, int> _replacements = <int, int>{};
  String _purpose = 'Business growth';
  int _months = 1;
  bool _consent = false;
  bool _submitting = false;

  MemberController get _controller => Get.find<MemberController>();
  Map<String, dynamic> get _context => _controller.loanContext;
  double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get _interest =>
      _amount * _number(_context['interestRate']) * _months / 100;
  String _money(Object? value) =>
      '${_controller.currency.value} ${_number(value).toStringAsFixed(2)}';

  Map<String, dynamic>? get _openLoan {
    final memberId = _integer(_context['groupMemberId']);
    const open = {'PENDING', 'UNDER_REVIEW', 'APPROVED', 'ACTIVE', 'DEFAULTED'};
    for (final loan in _controller.loanApplications) {
      if (_integer(loan['groupMemberId']) == memberId &&
          open.contains(loan['status']?.toString())) {
        return loan;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _controller.loadLoanData();
        if (!mounted) {
          return;
        }
        final preferred = _integer(_context['defaultDurationMonths']);
        final maximum = _integer(_context['maxDurationMonths']);
        setState(() => _months = preferred.clamp(1, maximum > 0 ? maximum : 1));
      } catch (error) {
        if (mounted) {
          Get.snackbar(
            'Could not load loans',
            error.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customPurposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    final required = _integer(_context['requiredGuarantors']);
    if (_guarantors.length != required) {
      Get.snackbar(
        'Choose guarantors',
        'Select exactly $required eligible guarantor${required == 1 ? '' : 's'}.',
      );
      return;
    }
    if (!_consent) {
      Get.snackbar(
        'Consent required',
        'Read and accept the loan terms before submitting.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _controller.applyForLoan(
        amount: _amount,
        durationMonths: _months,
        purpose: _purpose == 'Other'
            ? _customPurposeController.text.trim()
            : _purpose,
        guarantorIds: _guarantors.toList(),
      );
      if (!mounted) return;
      Get.snackbar(
        'Application submitted',
        required > 0
            ? 'Your guarantors have been asked to review the request.'
            : 'Your application has entered the approval workflow.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
      setState(() {});
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Application failed',
          error.toString().replaceFirst('Exception: ', ''),
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _replace(int loanId, int guaranteeId) async {
    final replacement = _replacements[guaranteeId];
    if (replacement == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _controller.replaceGuarantor(loanId, guaranteeId, replacement);
      if (mounted) {
        Get.snackbar(
          'Guarantor invited',
          'The replacement guarantor has been notified.',
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Could not replace guarantor',
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for a loan'), centerTitle: true),
      body: Obx(() {
        if (_context.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final existing = _openLoan;
        if (existing != null) return _existingApplication(existing);
        return _applicationForm();
      }),
    );
  }

  Widget _existingApplication(Map<String, dynamic> loan) {
    final guarantors = (loan['guarantors'] is List)
        ? (loan['guarantors'] as List)
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList()
        : <Map<String, dynamic>>[];
    final candidates = (_context['guarantors'] is List)
        ? (_context['guarantors'] as List)
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .where((item) => item['available'] == true)
              .toList()
        : <Map<String, dynamic>>[];
    return RefreshIndicator(
      onRefresh: _controller.loadLoanData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
        children: [
          _infoCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Application ${loan['loanNumber'] ?? ''}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusPill((loan['status'] ?? 'PENDING').toString()),
                SizedBox(height: 12.h),
                _detailRow('Requested amount', _money(loan['principalAmount'])),
                _detailRow('Total repayment', _money(loan['totalAmount'])),
                _detailRow('Period', '${loan['durationMonths']} months'),
                _detailRow('Purpose', (loan['purpose'] ?? '—').toString()),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Guarantors',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10.h),
          if (guarantors.isEmpty)
            const Text('No guarantors are required for this loan.'),
          ...guarantors.map((person) {
            final rejected = person['status'] == 'REJECTED';
            final guaranteeId = _integer(person['id']);
            return Card(
              margin: EdgeInsets.only(bottom: 10.h),
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (person['name'] ?? 'Guarantor').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _statusPill((person['status'] ?? 'PENDING').toString()),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '${person['phone'] ?? 'No phone'} · ${person['address'] ?? 'No address'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                    if (rejected) ...[
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<int>(
                        initialValue: _replacements[guaranteeId],
                        decoration: const InputDecoration(
                          labelText: 'Choose replacement guarantor',
                        ),
                        items: candidates
                            .map(
                              (candidate) => DropdownMenuItem(
                                value: _integer(candidate['id']),
                                child: Text(
                                  '${candidate['name']} · ${candidate['membershipNumber'] ?? ''}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _replacements[guaranteeId] = value!),
                      ),
                      SizedBox(height: 8.h),
                      FilledButton.icon(
                        onPressed:
                            _submitting || _replacements[guaranteeId] == null
                            ? null
                            : () => _replace(_integer(loan['id']), guaranteeId),
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Invite replacement'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 10.h),
          Text(
            'Pull down to refresh guarantor and approval status.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationForm() {
    final maxLoan = _number(_context['maximumLoan']);
    final maxMonths = _integer(_context['maxDurationMonths']);
    final required = _integer(_context['requiredGuarantors']);
    final candidates = (_context['guarantors'] is List)
        ? (_context['guarantors'] as List)
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList()
        : <Map<String, dynamic>>[];
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
        children: [
          _infoCard(
            icon: Icons.person_rounded,
            title: 'Applicant details',
            child: Column(
              children: [
                _detailRow('Full name', (_context['name'] ?? '—').toString()),
                _detailRow(
                  'Member number',
                  (_context['membershipNumber'] ?? '—').toString(),
                ),
                _detailRow(
                  'Identity number',
                  (_context['nationalId'] ?? 'Not provided').toString(),
                ),
                _detailRow(
                  'Phone',
                  (_context['phone'] ?? 'Not provided').toString(),
                ),
                _detailRow(
                  'Address',
                  (_context['address'] ?? 'Not provided').toString(),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          _infoCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Your borrowing limit',
            child: Column(
              children: [
                _detailRow(
                  'Current share value',
                  _money(_context['sharesValue']),
                ),
                _detailRow(
                  'Group multiplier',
                  '${_number(_context['loanMultiplier']).toStringAsFixed(2)}×',
                ),
                _detailRow('Maximum loan', _money(maxLoan), strong: true),
                _detailRow(
                  'Interest rate',
                  '${_number(_context['interestRate']).toStringAsFixed(2)}% per month',
                ),
                _detailRow(
                  'Kikoba end date',
                  (_context['groupEndDate'] ?? 'Not configured').toString(),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Loan request',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<String>(
            initialValue: _purpose,
            decoration: const InputDecoration(
              labelText: 'Purpose of the loan',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items:
                const [
                      'Business growth',
                      'School fees',
                      'Medical emergency',
                      'Home improvement',
                      'Agriculture',
                      'Other',
                    ]
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _purpose = value!),
          ),
          if (_purpose == 'Other') ...[
            SizedBox(height: 12.h),
            TextFormField(
              controller: _customPurposeController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Describe your purpose',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Describe the loan purpose'
                  : null,
            ),
          ],
          SizedBox(height: 12.h),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount requested',
              prefixText: '${_controller.currency.value} ',
              helperText: 'Maximum ${_money(maxLoan)}',
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null || amount <= 0) return 'Enter a valid amount';
              if (amount > maxLoan) {
                return 'Amount exceeds your borrowing limit';
              }
              return null;
            },
          ),
          SizedBox(height: 14.h),
          DropdownButtonFormField<int>(
            key: ValueKey('loan-duration-$_months-$maxMonths'),
            initialValue: maxMonths > 0 ? _months.clamp(1, maxMonths) : null,
            decoration: const InputDecoration(
              labelText: 'Repayment period',
              prefixIcon: Icon(Icons.calendar_month_rounded),
            ),
            items: [
              for (var month = 1; month <= maxMonths; month++)
                DropdownMenuItem(
                  value: month,
                  child: Text('$month month${month == 1 ? '' : 's'}'),
                ),
            ],
            onChanged: maxMonths <= 0
                ? null
                : (value) => setState(() => _months = value!),
            validator: (_) => maxMonths <= 0
                ? 'No repayment period fits before the group end date'
                : null,
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              children: [
                _detailRow('Principal', _money(_amount)),
                _detailRow('Interest amount', _money(_interest)),
                _detailRow(
                  'Total repayment',
                  _money(_amount + _interest),
                  strong: true,
                ),
                _detailRow(
                  'Estimated monthly payment',
                  _money(_months > 0 ? (_amount + _interest) / _months : 0),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Guarantors ($required required)',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5.h),
          Text(
            'Only eligible group members are selectable. Members with an open loan or another active guarantee are unavailable.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 10.h),
          if (required == 0)
            const Text('This group does not require guarantors.'),
          ...candidates.map((person) {
            final id = _integer(person['id']);
            final available = person['available'] == true;
            final selected = _guarantors.contains(id);
            return Card(
              margin: EdgeInsets.only(bottom: 9.h),
              child: CheckboxListTile(
                value: selected,
                onChanged: !available
                    ? null
                    : (checked) => setState(() {
                        if (checked == true && _guarantors.length < required) {
                          _guarantors.add(id);
                        } else if (checked == false) {
                          _guarantors.remove(id);
                        }
                      }),
                title: Text(
                  (person['name'] ?? 'Member').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${person['membershipNumber'] ?? ''} · ${person['phone'] ?? 'No phone'}\n${person['address'] ?? 'No address'}${available ? '' : '\n${person['reason'] ?? 'Not eligible'}'}',
                ),
                secondary: CircleAvatar(
                  child: Text(
                    (person['name'] ?? 'M')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          }),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applicant consent',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8.h),
                const Text(
                  'I confirm that the information provided is correct. I agree to repay the principal, interest and any configured late fines within the selected period and before the Kikoba end date.',
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  onChanged: (value) =>
                      setState(() => _consent = value ?? false),
                  title: const Text('I have read and accept the loan terms'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          FilledButton.icon(
            onPressed: _submitting || maxMonths <= 0 ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _submitting
                  ? 'Submitting application…'
                  : 'Submit loan application',
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(17.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            SizedBox(width: 11.w),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        child,
      ],
    ),
  );

  Widget _detailRow(String label, String value, {bool strong = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: strong ? 14.sp : 12.sp,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _statusPill(String status) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: status == 'REJECTED'
          ? AppColors.error.withValues(alpha: .1)
          : AppColors.primary.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: TextStyle(
        color: status == 'REJECTED' ? AppColors.error : AppColors.primary,
        fontSize: 10.sp,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class MemberGuaranteeRequestsPage extends StatefulWidget {
  const MemberGuaranteeRequestsPage({super.key});

  @override
  State<MemberGuaranteeRequestsPage> createState() =>
      _MemberGuaranteeRequestsPageState();
}

class _MemberGuaranteeRequestsPageState
    extends State<MemberGuaranteeRequestsPage> {
  int? _actingId;
  MemberController get _controller => Get.find<MemberController>();

  Future<void> _decide(int id, bool accept) async {
    if (_actingId != null) return;
    setState(() => _actingId = id);
    try {
      await _controller.decideGuarantee(id, accept);
      if (!mounted) return;
      Get.snackbar(
        accept ? 'Guarantee accepted' : 'Guarantee declined',
        accept
            ? 'The applicant can continue after every guarantor accepts.'
            : 'The applicant must choose a replacement guarantor.',
        backgroundColor: accept ? AppColors.primary : AppColors.error,
        colorText: Colors.white,
      );
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Decision failed',
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guarantee requests'),
        centerTitle: true,
      ),
      body: Obx(() {
        final requests = _controller.guaranteeRequests
            .where((item) => item['status'] == 'PENDING')
            .toList();
        return RefreshIndicator(
          onRefresh: _controller.loadLoanData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
            children: [
              if (requests.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 44.h,
                    horizontal: 20.w,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 42.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'No pending guarantee requests',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...requests.map((request) {
                  final id = request['id'] is num
                      ? (request['id'] as num).toInt()
                      : int.parse(request['id'].toString());
                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: .1,
                                ),
                                child: const Icon(
                                  Icons.handshake_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 11.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (request['applicantName'] ?? 'Member')
                                          .toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      (request['loanNumber'] ?? '').toString(),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'Guaranteed amount: ${_controller.currency.value} ${request['guaranteedAmount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            'Purpose: ${request['purpose'] ?? 'Not provided'}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _actingId == null
                                      ? () => _decide(id, false)
                                      : null,
                                  child: const Text('Decline'),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _actingId == null
                                      ? () => _decide(id, true)
                                      : null,
                                  child: _actingId == id
                                      ? const SizedBox.square(
                                          dimension: 17,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}

class MemberLoanApplicationsPage extends StatefulWidget {
  const MemberLoanApplicationsPage({super.key});

  @override
  State<MemberLoanApplicationsPage> createState() =>
      _MemberLoanApplicationsPageState();
}

class _MemberLoanApplicationsPageState
    extends State<MemberLoanApplicationsPage> {
  final MemberController _controller = Get.find<MemberController>();
  int? _actingId;

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(Object? value) =>
      '${_controller.currency.value} ${_number(value).toStringAsFixed(2)}';
  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _controller.loadLoanData();
      } catch (error) {
        if (mounted) _error('Could not load applications', error);
      }
    });
  }

  void _error(String title, Object error) => Get.snackbar(
    title,
    error.toString().replaceFirst('Exception: ', ''),
    backgroundColor: AppColors.error,
    colorText: Colors.white,
  );

  Future<String?> _reason(String action) async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action loan application'),
        content: TextField(
          controller: input,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Explain the decision clearly',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep application'),
          ),
          FilledButton(
            onPressed: () {
              final value = input.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(action),
          ),
        ],
      ),
    );
    input.dispose();
    return result;
  }

  Future<void> _act(Map<String, dynamic> loan, String action) async {
    if (_actingId != null) return;
    String? reason;
    if (action != 'approve' && action != 'disburse') {
      reason = await _reason(
        action == 'return'
            ? 'Return'
            : action == 'reject'
            ? 'Reject'
            : 'Cancel',
      );
      if (reason == null) return;
    }
    final id = _int(loan['id']);
    setState(() => _actingId = id);
    try {
      final result = await _controller.reviewLoan(id, action, reason: reason);
      if (!mounted) return;
      final active = result['status'] == 'ACTIVE';
      Get.snackbar(
        active ? 'Loan disbursed' : 'Decision saved',
        active
            ? 'The accountant approval completed the workflow. The loan and repayment schedule are now active.'
            : action == 'approve'
            ? 'Approved and moved to the next configured reviewer.'
            : action == 'return'
            ? 'Returned to the previous reviewer.'
            : 'The application was ${action}ed.',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (error) {
      if (mounted) _error('Decision failed', error);
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan applications'), centerTitle: true),
      body: Obx(() {
        final all = _controller.loanApplications.toList();
        final queue = all
            .where(
              (loan) => const {
                'PENDING',
                'UNDER_REVIEW',
                'APPROVED',
              }.contains(loan['status']),
            )
            .toList();
        final history = all
            .where(
              (loan) => !const {
                'PENDING',
                'UNDER_REVIEW',
                'APPROVED',
              }.contains(loan['status']),
            )
            .toList();
        return RefreshIndicator(
          onRefresh: _controller.loadLoanData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 30.h),
            children: [
              _workflowHeader(queue),
              SizedBox(height: 16.h),
              Text(
                'Approval queue',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10.h),
              if (queue.isEmpty)
                _empty('No applications are waiting for review.'),
              ...queue.map(_applicationCard),
              if (history.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Text(
                  'Loans and decisions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10.h),
                ...history.map(_historyTile),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _workflowHeader(List<Map<String, dynamic>> queue) => Container(
    padding: EdgeInsets.all(17.w),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF07513D)],
      ),
      borderRadius: BorderRadius.circular(22.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.account_tree_rounded, color: Colors.white),
        SizedBox(height: 12.h),
        Text(
          'Chair → Accountant → Disbursement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          'The saved group workflow starts after every guarantor accepts. The final accountant approval activates the loan and creates its repayment schedule.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .78),
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 8.w,
          children: [
            _headerCount(
              '${queue.where((loan) => loan['status'] == 'PENDING').length}',
              'Guarantors',
            ),
            _headerCount(
              '${queue.where((loan) => loan['status'] == 'UNDER_REVIEW').length}',
              'In review',
            ),
            _headerCount(
              '${queue.where((loan) => loan['canApprove'] == true).length}',
              'Your action',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _headerCount(String value, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(
      '$value $label',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _applicationCard(Map<String, dynamic> loan) {
    final id = _int(loan['id']);
    final status = (loan['status'] ?? 'PENDING').toString();
    final steps = _list(loan['approvalSteps']);
    final current = steps.cast<Map<String, dynamic>?>().firstWhere(
      (step) => step?['approvedAt'] == null,
      orElse: () => null,
    );
    final guarantors = _list(loan['guarantors']);
    final events = _list(loan['approvalEvents']);
    final loading = _actingId == id;
    return Card(
      margin: EdgeInsets.only(bottom: 13.h),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (loan['memberName'] ?? 'Member').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${loan['loanNumber'] ?? ''} · ${loan['purpose'] ?? ''}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                _loanStatus(status),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _metric('Principal', _money(loan['principalAmount'])),
                ),
                Expanded(
                  child: _metric('Total due', _money(loan['totalAmount'])),
                ),
                Expanded(
                  child: _metric('Period', '${loan['durationMonths']} mo'),
                ),
              ],
            ),
            if (guarantors.isNotEmpty) ...[
              SizedBox(height: 13.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: guarantors
                    .map(
                      (person) => Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          person['status'] == 'ACCEPTED'
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 16,
                          color: person['status'] == 'ACCEPTED'
                              ? AppColors.primary
                              : Colors.amber.shade800,
                        ),
                        label: Text(
                          '${person['name']} · ${person['status']}',
                          style: TextStyle(fontSize: 9.sp),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (steps.isNotEmpty) ...[
              SizedBox(height: 14.h),
              _stepsTable(steps, current),
            ],
            if (events.isNotEmpty) ...[
              SizedBox(height: 12.h),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Decision history',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                children: events
                    .map(
                      (event) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history_rounded, size: 19),
                        title: Text(
                          (event['action'] ?? '').toString().replaceAll(
                            '_',
                            ' ',
                          ),
                        ),
                        subtitle: Text(
                          '${event['actedAt'] ?? ''}${event['reason'] == null ? '' : '\n${event['reason']}'}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: 12.h),
            if (status == 'PENDING')
              const Text('Waiting for every guarantor to accept.')
            else if (loan['canApprove'] == true)
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  FilledButton.icon(
                    onPressed: loading ? null : () => _act(loan, 'approve'),
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      current?['role'] == 'ACCOUNTANT'
                          ? 'Approve & disburse'
                          : 'Approve step',
                    ),
                  ),
                  if (steps.any(
                    (step) =>
                        _int(step['stepOrder']) < _int(current?['stepOrder']) &&
                        step['approvedByMemberId'] != null,
                  ))
                    OutlinedButton.icon(
                      onPressed: loading ? null : () => _act(loan, 'return'),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Return'),
                    ),
                  OutlinedButton(
                    onPressed: loading ? null : () => _act(loan, 'reject'),
                    child: const Text('Reject'),
                  ),
                ],
              )
            else
              Text(
                'Waiting for ${current?['label'] ?? 'the configured reviewer'}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (loan['canCancel'] == true) ...[
              SizedBox(height: 8.h),
              TextButton.icon(
                onPressed: loading ? null : () => _act(loan, 'cancel'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel application'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepsTable(
    List<Map<String, dynamic>> steps,
    Map<String, dynamic>? current,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 18.w,
      headingRowHeight: 36.h,
      dataRowMinHeight: 40.h,
      dataRowMaxHeight: 52.h,
      columns: const [
        DataColumn(label: Text('STEP')),
        DataColumn(label: Text('REVIEWER')),
        DataColumn(label: Text('STATUS')),
      ],
      rows: steps.map((step) {
        final done = step['approvedAt'] != null;
        final active = step['stepOrder'] == current?['stepOrder'];
        return DataRow(
          cells: [
            DataCell(Text('${step['stepOrder']}')),
            DataCell(Text((step['label'] ?? step['role']).toString())),
            DataCell(
              _loanStatus(
                done
                    ? 'APPROVED'
                    : active
                    ? 'CURRENT'
                    : 'WAITING',
              ),
            ),
          ],
        );
      }).toList(),
    ),
  );

  Widget _historyTile(Map<String, dynamic> loan) => Card(
    margin: EdgeInsets.only(bottom: 9.h),
    child: ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(
        '${loan['loanNumber']} · ${loan['memberName']}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_money(loan['principalAmount'])} · ${loan['status'].toString().replaceAll('_', ' ')}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Get.to(() => MemberLoanDetailsPage(loan: loan)),
    ),
  );

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 9.sp, color: AppColors.textSecondary),
      ),
      SizedBox(height: 3.h),
      Text(
        value,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
      ),
    ],
  );

  Widget _loanStatus(String status) {
    final bad =
        status == 'REJECTED' || status == 'CANCELLED' || status == 'OVERDUE';
    final waiting =
        status == 'PENDING' || status == 'WAITING' || status == 'CURRENT';
    final color = bad
        ? AppColors.error
        : waiting
        ? Colors.amber.shade800
        : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 8.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _empty(String text) => Container(
    padding: EdgeInsets.all(28.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Center(child: Text(text)),
  );
}

class MemberLoanDetailsPage extends StatefulWidget {
  const MemberLoanDetailsPage({super.key, required this.loan});
  final Map<String, dynamic> loan;

  @override
  State<MemberLoanDetailsPage> createState() => _MemberLoanDetailsPageState();
}

class _MemberLoanDetailsPageState extends State<MemberLoanDetailsPage> {
  final MemberController _controller = Get.find<MemberController>();
  bool _loading = true;
  List<Map<String, dynamic>> _schedule = <Map<String, dynamic>>[];
  double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(Object? value) =>
      '${_controller.currency.value} ${_number(value).toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _schedule = await _controller.loadLoanSchedule(
        (widget.loan['id'] as num).toInt(),
      );
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Schedule unavailable',
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final lateFine = _number(loan['latePaymentFine']);
    final appliedFines = _schedule.fold<double>(
      0,
      (sum, row) => sum + _number(row['penaltyAmount']),
    );
    return Scaffold(
      appBar: AppBar(title: Text('${loan['loanNumber']}'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 30.h),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (loan['memberName'] ?? 'Member').toString(),
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _row('Principal', _money(loan['principalAmount'])),
                  _row('Interest', _money(loan['interestAmount'])),
                  _row('Total due', _money(loan['totalAmount'])),
                  _row('Outstanding', _money(loan['remainingBalance'])),
                  _row('Disbursed', '${loan['disbursementDate'] ?? 'Waiting'}'),
                  _row('Maturity', '${loan['maturityDate'] ?? 'Waiting'}'),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: _summary('Installments', '${_schedule.length}')),
              SizedBox(width: 8.w),
              Expanded(child: _summary('Fine if missed', _money(lateFine))),
              SizedBox(width: 8.w),
              Expanded(child: _summary('Fines applied', _money(appliedFines))),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            'Repayment schedule',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 9.h),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_schedule.isEmpty)
            const Text(
              'The schedule is created after accountant approval and disbursement.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('DUE')),
                  DataColumn(label: Text('PRINCIPAL')),
                  DataColumn(label: Text('INTEREST')),
                  DataColumn(label: Text('LATE FINE')),
                  DataColumn(label: Text('BALANCE')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: _schedule
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text('${row['installmentNumber']}')),
                          DataCell(Text('${row['dueDate']}')),
                          DataCell(Text(_money(row['principalAmount']))),
                          DataCell(Text(_money(row['interestAmount']))),
                          DataCell(
                            Text(
                              _money(
                                _number(row['penaltyAmount']) > 0
                                    ? row['penaltyAmount']
                                    : lateFine,
                              ),
                            ),
                          ),
                          DataCell(Text(_money(row['balance']))),
                          DataCell(Text('${row['status']}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  Widget _summary(String label, String value) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(13.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class MemberFinesPage extends StatelessWidget {
  const MemberFinesPage({super.key});

  double _amount(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  String _money(Object? value, String currency) =>
      '$currency ${_amount(value).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MemberController>();
    return Scaffold(
      appBar: AppBar(title: const Text('My fines'), centerTitle: true),
      body: Obx(() {
        final fines = controller.memberFines;
        final outstanding = fines.fold<double>(
          0,
          (total, fine) => total + _amount(fine['balance']),
        );
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
            children: [
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding fines',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _money(outstanding, controller.currency.value),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              if (fines.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 42.h,
                    horizontal: 20.w,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 40.sp,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'You have no fines',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Any fines issued to you will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...fines.map((fine) {
                  final status = (fine['status'] ?? 'UNPAID').toString();
                  final paid = status == 'PAID' || status == 'WAIVED';
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: (paid ? AppColors.primary : AppColors.error)
                                .withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          child: Icon(
                            paid ? Icons.check_rounded : Icons.gavel_rounded,
                            color: paid ? AppColors.primary : AppColors.error,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (fine['fineTypeName'] ?? 'Fine')
                                          .toString(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    status.replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: paid
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                fine['reason']?.toString().trim().isNotEmpty ==
                                        true
                                    ? fine['reason'].toString()
                                    : 'No additional reason provided.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 9.h),
                              Text(
                                'Balance: ${_money(fine['balance'], controller.currency.value)}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                'Issued ${fine['fineDate'] ?? '—'} · Due ${fine['dueDate'] ?? '—'}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}

class MemberMeetingsPage extends StatefulWidget {
  const MemberMeetingsPage({super.key});

  @override
  State<MemberMeetingsPage> createState() => _MemberMeetingsPageState();
}

class _MemberMeetingsPageState extends State<MemberMeetingsPage> {
  final MemberController _controller = Get.find<MemberController>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _controller.loadMeetings();
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Meetings unavailable',
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My meetings'), centerTitle: true),
      body: Obx(() {
        final meetings = _controller.groupMeetings;
        if (_loading && meetings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group meeting assignments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Open a meeting to see its agenda, venue, link, status and your attendance assignment.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .76),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
              if (meetings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No meetings have been assigned to this group.',
                    ),
                  ),
                )
              else
                ...meetings.map((meeting) => _meetingCard(meeting)),
            ],
          ),
        );
      }),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final status = (meeting['status'] ?? 'SCHEDULED').toString();
    return Card(
      margin: EdgeInsets.only(bottom: 11.h),
      child: InkWell(
        onTap: () => Get.to(() => MemberMeetingDetailPage(meeting: meeting)),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (meeting['title'] ?? 'Group meeting').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${meeting['meetingDate'] ?? 'Date TBD'} · ${meeting['startTime'] ?? 'Time TBD'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11.sp,
                      ),
                    ),
                    Text(
                      (meeting['location'] ??
                              meeting['meetingMode'] ??
                              'Venue TBD')
                          .toString(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _meetingStatus(status),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meetingStatus(String status) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 8.sp,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class MemberMeetingDetailPage extends StatefulWidget {
  const MemberMeetingDetailPage({required this.meeting, super.key});

  final Map<String, dynamic> meeting;

  @override
  State<MemberMeetingDetailPage> createState() =>
      _MemberMeetingDetailPageState();
}

class _MemberMeetingDetailPageState extends State<MemberMeetingDetailPage> {
  final MemberController _controller = Get.find<MemberController>();
  late Map<String, dynamic> _meeting;
  Map<String, dynamic> _attendance = <String, dynamic>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _meeting = Map<String, dynamic>.from(widget.meeting);
    _load();
  }

  Future<void> _load() async {
    final rawId = _meeting['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final details = await _controller.loadMeetingDetails(id);
      if (!mounted) return;
      setState(() {
        _meeting = details;
        _attendance = Map<String, dynamic>.from(
          _controller.meetingAttendance[id] ?? <String, dynamic>{},
        );
      });
    } catch (error) {
      if (mounted) {
        Get.snackbar(
          'Meeting details unavailable',
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _meeting['title']?.toString() ?? 'Meeting';
    final date = _meeting['meetingDate']?.toString() ?? 'Date TBD';
    final start = _meeting['startTime']?.toString() ?? 'Time TBD';
    final end = _meeting['endTime']?.toString();
    final time = end == null ? start : '$start – $end';
    final venue = _meeting['location']?.toString() ?? 'Venue TBD';
    final mode = _meeting['meetingMode']?.toString() ?? 'IN PERSON';
    final link = _meeting['meetingLink']?.toString();
    final status = _meeting['status']?.toString() ?? 'SCHEDULED';
    final agenda = _meeting['agenda']?.toString() ?? 'No agenda specified yet.';
    final attendanceStatus =
        _attendance['status']?.toString() ?? 'NOT RECORDED';

    return Scaffold(
      appBar: AppBar(title: const Text('Meeting details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                date,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                time,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.flag_outlined, size: 17),
                          label: Text(status.replaceAll('_', ' ')),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.person_pin_circle_outlined,
                            size: 17,
                          ),
                          label: Text(
                            'My attendance: ${attendanceStatus.replaceAll('_', ' ')}',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    _detailSection(
                      context,
                      Icons.place_outlined,
                      'Venue and mode',
                      '$venue\n${mode.replaceAll('_', ' ')}${link == null || link.isEmpty ? '' : '\n$link'}',
                    ),
                    SizedBox(height: 16.h),
                    _detailSection(
                      context,
                      Icons.assignment_outlined,
                      'Your assignment',
                      _attendance.isEmpty
                          ? 'You are invited as a group member. Attendance has not been recorded yet.'
                          : 'Attendance: ${attendanceStatus.replaceAll('_', ' ')}${_attendance['arrivalTime'] == null ? '' : '\nArrival: ${_attendance['arrivalTime']}'}${_attendance['reason'] == null ? '' : '\nNote: ${_attendance['reason']}'}',
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Agenda',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      agenda,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.done_rounded),
                        label: const Text('Back to meetings'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _detailSection(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(15.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(width: 11.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 5.h),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
