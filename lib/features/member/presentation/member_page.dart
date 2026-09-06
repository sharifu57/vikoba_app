import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/app/widgets/vikoba_logo.dart';
import 'member_controller.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MemberController>(
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _HomeView(controller: controller),
                _ActivityView(controller: controller),
                const _ProfileView(),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => selectedIndex = index),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.secondary.withValues(alpha: .24),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.controller});
  final MemberController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const _LoadingView();
      if (controller.errorMessage.value != null) {
        return _ErrorView(
          message: controller.errorMessage.value!,
          onRetry: controller.loadDashboard,
        );
      }
      final summary = controller.summary;
      final finance = controller.finance;
      final actions = controller.actions;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadDashboard,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
          children: [
            Row(
              children: [
                const VikobaLogo(size: 42, showName: true, nameSize: 18),
                const Spacer(),
                _RoundButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Text(
              'Good day, member',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your circle at a glance.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 27.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            SizedBox(height: 22.h),
            _BalanceCard(
              controller: controller,
              summary: summary,
              finance: finance,
            ),
            SizedBox(height: 22.h),
            _SectionTitle(title: 'Your progress', action: 'This year'),
            SizedBox(height: 12.h),
            _ContributionChart(
              points: controller.contributionTrend,
              currency: controller.currency.value,
            ),
            SizedBox(height: 22.h),
            _SectionTitle(
              title: 'Group pulse',
              action: '${summary['totalMembers'] ?? 0} members',
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.savings_outlined,
                    label: 'Contributions',
                    value: _money(
                      summary['contributions'],
                      controller.currency.value,
                    ),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Loan balance',
                    value: _money(
                      summary['outstandingLoans'],
                      controller.currency.value,
                    ),
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Open actions',
                    value:
                        '${(actions['pendingLoanApplications'] ?? 0) + (actions['unpaidFines'] ?? 0)}',
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Received',
                    value: _money(
                      finance['totalReceived'],
                      controller.currency.value,
                    ),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            _SectionTitle(title: 'Recent activity', action: 'See all'),
            SizedBox(height: 10.h),
            ...controller.activities
                .take(4)
                .map(
                  (activity) => _ActivityTile(
                    activity: activity,
                    currency: controller.currency.value,
                  ),
                ),
            if (controller.activities.isEmpty)
              const _EmptyLine(text: 'Your group activity will appear here.'),
          ],
        ),
      );
    });
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.controller,
    required this.summary,
    required this.finance,
  });
  final MemberController controller;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> finance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                controller.groupName.value,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.verified_rounded,
                color: AppColors.secondary,
                size: 19.sp,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Group fund received',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .64),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _money(finance['totalReceived'], controller.currency.value),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _CardStat(
                  label: 'Share capital',
                  value: _money(
                    summary['shareCapital'],
                    controller.currency.value,
                  ),
                ),
              ),
              Expanded(
                child: _CardStat(
                  label: 'Outstanding loans',
                  value: _money(
                    summary['outstandingLoans'],
                    controller.currency.value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributionChart extends StatelessWidget {
  const _ContributionChart({required this.points, required this.currency});
  final List<Map<String, dynamic>> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => _number(point['amount'])).toList();
    final maxValue = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);
    final chart = LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue == 0 ? 100 : maxValue * 1.2,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: .12),
            ),
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
          ),
        ],
      ),
    );
    return Container(
      height: 190.h,
      padding: EdgeInsets.fromLTRB(8.w, 18.h, 18.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: values.isEmpty
          ? const _EmptyLine(text: 'Contribution trend will appear here.')
          : chart,
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView({required this.controller});
  final MemberController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
        children: [
          const VikobaLogo(size: 42, showName: true, nameSize: 18),
          SizedBox(height: 30.h),
          Text(
            'Activity',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'A clear record of what is happening in your group.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 20.h),
          ...controller.activities.map(
            (activity) => _ActivityTile(
              activity: activity,
              currency: controller.currency.value,
            ),
          ),
          if (controller.activities.isEmpty)
            const _EmptyLine(text: 'No recent activity yet.'),
        ],
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
    children: [
      const VikobaLogo(size: 42, showName: true, nameSize: 18),
      SizedBox(height: 30.h),
      Text(
        'Your profile',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 28.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
      SizedBox(height: 18.h),
      const _EmptyLine(text: 'Profile settings will be available here.'),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
      const Spacer(),
      Text(
        action,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15.r),
    child: Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21.sp),
    ),
  );
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .56),
          fontSize: 10.sp,
        ),
      ),
      SizedBox(height: 3.h),
      Text(
        value,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21.sp),
        SizedBox(height: 11.h),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.currency});

  final Map<String, dynamic> activity;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final type =
        activity['type']?.toString().replaceAll('_', ' ') ?? 'Group payment';
    final description =
        activity['description']?.toString() ??
        activity['reference']?.toString() ??
        'Recorded activity';
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(13.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 37.w,
              height: 37.w,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _money(activity['amount'], currency),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 22.h),
    child: Center(
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
      ),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VikobaLogo(size: 72),
          SizedBox(height: 18.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 18.h),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String _money(Object? value, String currency) =>
    '$currency ${_number(value).toStringAsFixed(0)}';
double _number(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
