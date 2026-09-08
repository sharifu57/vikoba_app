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
  final _jamiiAmountController = TextEditingController();
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

  int get _requestedQuantity {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_sharePrice <= 0) return 0;
    return (amount / _sharePrice).floor();
  }

  double get _configuredJamiiAmount =>
      _number(_controller.shareSummary['jamiiContributionPerSharePayment']);

  @override
  void dispose() {
    _amountController.dispose();
    _jamiiAmountController.dispose();
    _paymentReferenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final amount = double.parse(_amountController.text.trim());
    final quantity = _requestedQuantity;
    setState(() => _isSubmitting = true);

    try {
      await _controller.submitSharePurchaseProof(
        quantity: quantity,
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentReference: _paymentReferenceController.text.trim(),
        proofText: _noteController.text.trim(),
        proofFilePath: _proofFilePath,
        jamiiAmount: double.tryParse(_jamiiAmountController.text.trim()),
      );
      if (!mounted) return;
      Get.snackbar(
        'Proof submitted for review',
        '$quantity share${quantity == 1 ? '' : 's'} await admin or accountant approval.',
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
        allowMultiple: false,
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
                  'Purchase amount',
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
                    if (amount < _sharePrice) {
                      return 'Amount must buy at least one share';
                    }
                    if (_paymentReferenceController.text.trim().isEmpty &&
                        _noteController.text.trim().isEmpty &&
                        _proofFilePath == null) {
                      return 'Add an M-Pesa reference, proof text, or file';
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
                  controller: _jamiiAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${_controller.currency.value} ',
                    hintText: _configuredJamiiAmount > 0
                        ? _configuredJamiiAmount.toStringAsFixed(0)
                        : 'Optional amount',
                    helperText: 'Separate from the share purchase amount.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                    '$_requestedQuantity share${_requestedQuantity == 1 ? '' : 's'} will be purchased for ${_controller.currency.value} ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(0) ?? '0'}',
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
  final _purposeController = TextEditingController();
  final _monthsController = TextEditingController(text: '12');

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request loan')),
      body: SingleChildScrollView(
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
                  color: AppColors.accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan estimate',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Monthly repayment: TZS ${_monthlyEstimate()} ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Loan amount',
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
                  hintText: '500000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a loan amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18.h),
              Text(
                'Purpose',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  hintText: 'Business growth, emergency, school fees...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please explain the loan purpose';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18.h),
              Text(
                'Repayment period (months)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '12',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Get.snackbar(
                        'Loan request not submitted',
                        'Loan submission is not available until a loan product is selected.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: const Icon(Icons.request_quote_rounded),
                  label: const Text('Submit request'),
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

  String _monthlyEstimate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 12;
    if (months <= 0 || amount <= 0) return '0';
    return (amount / months).toStringAsFixed(0);
  }
}

class MemberMeetingsPage extends StatelessWidget {
  const MemberMeetingsPage({super.key});

  static const List<Map<String, dynamic>> demoMeetings = [
    {
      'title': 'General Meeting',
      'date': 'Tue, 12 Sep 2026',
      'time': '10:00 AM',
      'venue': 'Kigamboni Community Hall',
      'agenda':
          'Review monthly contributions, approve new members, and discuss share distributions.',
    },
    {
      'title': 'Savings Review',
      'date': 'Thu, 26 Sep 2026',
      'time': '04:00 PM',
      'venue': 'Mbezi Group Office',
      'agenda':
          'Review savings progress and discuss upcoming emergency fund support targets.',
    },
    {
      'title': 'Loan Committee',
      'date': 'Mon, 30 Sep 2026',
      'time': '09:30 AM',
      'venue': 'Jangwani Meeting Room',
      'agenda':
          'Review loan applications and approve disbursement schedules for this month.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
        itemCount: demoMeetings.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final meeting = demoMeetings[index];
          final title = meeting['title'] as String;
          final date = meeting['date'] as String;
          final time = meeting['time'] as String;
          final venue = meeting['venue'] as String;

          return InkWell(
            onTap: () =>
                Get.to(() => MemberMeetingDetailPage(meeting: meeting)),
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: AppColors.primary.withValues(alpha: .12),
                    ),
                    child: Icon(Icons.event_rounded, color: AppColors.primary),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$date • $time',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          venue,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MemberMeetingDetailPage extends StatelessWidget {
  const MemberMeetingDetailPage({required this.meeting, super.key});

  final Map<String, dynamic> meeting;

  @override
  Widget build(BuildContext context) {
    final title = meeting['title'] as String? ?? 'Meeting';
    final date = meeting['date'] as String? ?? 'Date TBD';
    final time = meeting['time'] as String? ?? 'Time TBD';
    final venue = meeting['venue'] as String? ?? 'Venue TBD';
    final agenda = meeting['agenda'] as String? ?? 'No agenda specified yet.';

    return Scaffold(
      appBar: AppBar(title: const Text('Meeting details')),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
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
                      Text(date, style: const TextStyle(color: Colors.white)),
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
                      Text(time, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Venue',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              venue,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 22.h),
            Text(
              'Agenda',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              agenda,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13.sp,
                height: 1.6,
              ),
            ),
            const Spacer(),
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
      ),
    );
  }
}
