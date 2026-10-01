import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';

class GroupSelectionPage extends StatefulWidget {
  const GroupSelectionPage({super.key});

  @override
  State<GroupSelectionPage> createState() => _GroupSelectionPageState();
}

class _GroupSelectionPageState extends State<GroupSelectionPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await TokenStorage.getGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Your group list could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, dynamic> membership) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await TokenStorage.selectGroup(membership);
      Get.offAllNamed('/member');
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('FormatException: ', '');
        });
      }
    }
  }

  Map<String, dynamic> _group(Map<String, dynamic> membership) {
    final value = membership['group'];
    return value is Map ? Map<String, dynamic>.from(value) : membership;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 32.h),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 11.w),
                      Text(
                        'VIKOBA360',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 42.h),
                  Text(
                    'YOUR GROUPS',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    'Where would you like to go?',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    'Choose a group to open its dashboard and records.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  if (_groups.isEmpty && _error == null)
                    const Text('No active group memberships were found.')
                  else
                    ..._groups.map((membership) {
                      final group = _group(membership);
                      final name =
                          (group['groupName'] ??
                                  group['name'] ??
                                  'Vikoba group')
                              .toString();
                      final organization = (group['organizationName'] ?? '')
                          .toString();
                      final code = (group['groupCode'] ?? group['code'] ?? '')
                          .toString();
                      final role = (membership['role'] ?? 'MEMBER')
                          .toString()
                          .replaceAll('_', ' ');
                      final currency = (group['currency'] ?? 'TZS').toString();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 11.h),
                        child: Material(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(17.r),
                          child: InkWell(
                            onTap: _saving ? null : () => _select(membership),
                            borderRadius: BorderRadius.circular(17.r),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17.r),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48.w,
                                    height: 48.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: .09,
                                      ),
                                      borderRadius: BorderRadius.circular(15.r),
                                    ),
                                    child: Text(
                                      name.trim().isEmpty
                                          ? 'V'
                                          : name.trim()[0].toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 13.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (organization.isNotEmpty ||
                                            code.isNotEmpty) ...[
                                          SizedBox(height: 3.h),
                                          Text(
                                            [organization, code]
                                                .where(
                                                  (value) => value.isNotEmpty,
                                                )
                                                .join(' · '),
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: 9.h),
                                        Wrap(
                                          spacing: 7.w,
                                          runSpacing: 5.h,
                                          children: [
                                            _GroupTag(
                                              icon: Icons.badge_outlined,
                                              label: role,
                                            ),
                                            _GroupTag(
                                              icon: Icons.payments_outlined,
                                              label: currency,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 19.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (_saving)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _GroupTag extends StatelessWidget {
  const _GroupTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.primary),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
