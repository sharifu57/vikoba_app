import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:vikoba_app/app/constants/app_colors.dart';
import 'package:vikoba_app/app/widgets/vikoba_logo.dart';
import 'package:vikoba_app/core/storage/token_storage.dart';
import 'member_action_pages.dart';
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
                _ProfileView(controller: controller),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => selectedIndex = index),
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: AppColors.secondary.withValues(alpha: .24),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up_rounded),
                label: 'Shares',
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
      final greeting = TokenStorage.getGreetingForTime(
        DateTime.now().hour,
        controller.memberName.value,
      );
      final guaranteeCount = controller.guaranteeRequests
          .where(
            (request) =>
                request['status']?.toString().toUpperCase() == 'PENDING',
          )
          .length;
      final loanApprovalCount = controller.loanApplications
          .where(
            (loan) => loan['canApprove'] == true || loan['canDisburse'] == true,
          )
          .length;

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
                  badge: guaranteeCount + loanApprovalCount,
                  onTap: () => Get.to(
                    () => loanApprovalCount > 0
                        ? const MemberLoanApplicationsPage()
                        : const MemberGuaranteeRequestsPage(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            Text(
              greeting,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              controller.groupName.value,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 27.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            SizedBox(height: 12.h),
            _QuickActionsRow(),
            SizedBox(height: 20.h),
            _BalanceCard(controller: controller),
            SizedBox(height: 22.h),
            _SectionTitle(title: 'Share history', action: 'Last 6 months'),
            SizedBox(height: 12.h),
            _ShareHistoryChart(
              transactions: controller.shareLedger.toList(),
              currency: controller.currency.value,
            ),
            SizedBox(height: 22.h),
            _SectionTitle(title: 'My share summary', action: 'Personal'),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.savings_outlined,
                    label: 'My shares',
                    value: '${controller.shareSummary['totalShares'] ?? 0}',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'My share value',
                    value: _money(
                      controller.shareSummary['totalCapital'] ??
                          summary['shareCapital'] ??
                          0,
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
                    icon: Icons.trending_up_rounded,
                    label: 'Latest purchase',
                    value: controller.shareLedger.isEmpty
                        ? 'None yet'
                        : _money(
                            controller.shareLedger.first['totalAmount'],
                            controller.currency.value,
                          ),
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Price per share',
                    value: _money(
                      controller.shareSummary['sharePrice'] ?? 0,
                      controller.currency.value,
                    ),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            _SectionTitle(title: 'Meetings', action: 'Upcoming'),
            SizedBox(height: 10.h),
            if (controller.meetings.isEmpty)
              const _EmptyLine(text: 'No meetings scheduled yet.')
            else
              ...controller.meetings
                  .take(2)
                  .map((meeting) => _MeetingTile(meeting: meeting)),
          ],
        ),
      );
    });
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.controller});
  final MemberController controller;

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
            'My share value',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .64),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _money(
              controller.shareSummary['totalCapital'],
              controller.currency.value,
            ),
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
                  label: 'My shares',
                  value: '${controller.shareSummary['totalShares'] ?? 0} units',
                ),
              ),
              Expanded(
                child: _CardStat(
                  label: 'My purchases',
                  value: '${controller.shareLedger.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareHistoryChart extends StatelessWidget {
  const _ShareHistoryChart({
    required this.transactions,
    required this.currency,
  });
  final List<Map<String, dynamic>> transactions;
  final String currency;

  List<_ShareMonthPoint> get _monthlyHistory {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final offset = 5 - index;
      return DateTime(now.year, now.month - offset);
    });
    final totals = <String, double>{};
    for (final transaction in transactions) {
      final date = DateTime.tryParse(
        transaction['transactionDate']?.toString() ?? '',
      );
      if (date == null) continue;
      final key = '${date.year}-${date.month}';
      totals[key] = (totals[key] ?? 0) + _number(transaction['totalAmount']);
    }
    return [
      for (final month in months)
        _ShareMonthPoint(
          month: month,
          amount: totals['${month.year}-${month.month}'] ?? 0,
        ),
    ];
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = _monthlyHistory;
    final values = history.map((point) => point.amount).toList();
    final hasHistory = values.any((amount) => amount > 0);
    final total = values.fold<double>(0, (sum, amount) => sum + amount);
    final firstMonth = history.first.month;
    final purchaseCount = transactions.where((transaction) {
      final date = DateTime.tryParse(
        transaction['transactionDate']?.toString() ?? '',
      );
      return date != null && !date.isBefore(firstMonth);
    }).length;
    final maxValue = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue == 0 ? 100.0 : maxValue * 1.25;
    final interval = chartMax / 4;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: hasHistory
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 6 months',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$currency ${NumberFormat('#,##0').format(total)}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$purchaseCount purchases',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  height: 164.h,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (history.length - 1).toDouble(),
                      minY: 0,
                      maxY: chartMax,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: .55,
                          ),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35.w,
                            interval: interval,
                            getTitlesWidget: (value, _) => Text(
                              _compactMoney(value),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 8.sp,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26.h,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final index = value.round();
                              if (index < 0 || index >= history.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  DateFormat(
                                    'MMM',
                                  ).format(history[index].month),
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.primary,
                          getTooltipItems: (spots) => spots.map((spot) {
                            final month = history[spot.x.round()].month;
                            return LineTooltipItem(
                              '${DateFormat('MMMM').format(month)}\n$currency ${NumberFormat('#,##0').format(spot.y)}',
                              TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          curveSmoothness: .28,
                          color: AppColors.primary,
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, _, _) =>
                                FlDotCirclePainter(
                                  radius: spot.y > 0 ? 3.5 : 2,
                                  color: spot.y > 0
                                      ? AppColors.secondary
                                      : colorScheme.outlineVariant,
                                  strokeWidth: 2,
                                  strokeColor: colorScheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: .22),
                                AppColors.primary.withValues(alpha: .01),
                              ],
                            ),
                          ),
                          spots: [
                            for (var i = 0; i < history.length; i++)
                              FlSpot(i.toDouble(), history[i].amount),
                          ],
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ],
            )
          : SizedBox(
              height: 150.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 35.sp,
                    color: AppColors.primary.withValues(alpha: .35),
                  ),
                  SizedBox(height: 10.h),
                  const _EmptyLine(
                    text: 'Your share purchase history will appear here.',
                  ),
                ],
              ),
            ),
    );
  }
}

class _ShareMonthPoint {
  const _ShareMonthPoint({required this.month, required this.amount});

  final DateTime month;
  final double amount;
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
            'My shares',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your share purchases and current share activity.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 20.h),
          ...controller.shareLedger.map(
            (activity) => _ActivityTile(
              activity: activity,
              currency: controller.currency.value,
            ),
          ),
          if (controller.shareLedger.isEmpty)
            const _EmptyLine(text: 'No share purchases yet.'),
        ],
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.controller});

  final MemberController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colorScheme = Theme.of(context).colorScheme;
      final displayName = controller.memberName.value;
      final initials = displayName.trim().isEmpty
          ? 'M'
          : displayName.trim().split(RegExp(r'\s+')).length > 1
          ? '${displayName.trim().split(RegExp(r'\s+'))[0][0]}${displayName.trim().split(RegExp(r'\s+'))[1][0]}'
                .toUpperCase()
          : displayName.trim().substring(0, 1).toUpperCase();

      return ListView(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
        children: [
          const VikobaLogo(size: 42, showName: true, nameSize: 18),
          SizedBox(height: 28.h),
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38.r,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  displayName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  controller.memberProfile['role']?.toString() ??
                      controller.currentGroupRole.value,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  controller.memberProfile['phone']?.toString() ??
                      'No phone available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.savings_outlined,
                  label: 'Shares',
                  value: '${controller.shareSummary['totalShares'] ?? 0} units',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MetricCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Purchases',
                  value: '${controller.shareLedger.length}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _ProfileActionItem(
            label: 'Buy shares',
            icon: Icons.trending_up_rounded,
            onTap: () => Get.to(() => const MemberSharePurchasePage()),
          ),
          _ProfileActionItem(
            label: 'Request loan',
            icon: Icons.request_quote_outlined,
            onTap: () => Get.to(() => const MemberLoanRequestPage()),
          ),
          _ProfileActionItem(
            label: 'View meetings',
            icon: Icons.event_available_rounded,
            onTap: () => Get.to(() => const MemberMeetingsPage()),
          ),
          _ProfileActionItem(
            label: Get.isDarkMode ? 'Use light theme' : 'Use dark theme',
            icon: Get.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            onTap: () async {
              final useDarkTheme = !Get.isDarkMode;
              await TokenStorage.saveDarkTheme(useDarkTheme);
              Get.changeThemeMode(
                useDarkTheme ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          _ProfileActionItem(
            label: 'Logout',
            icon: Icons.logout_rounded,
            onTap: () async => await Get.find<MemberController>().logout(),
            accent: true,
          ),
        ],
      );
    });
  }
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
          color: Theme.of(context).colorScheme.onSurface,
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
  const _RoundButton({required this.icon, required this.onTap, this.badge = 0});
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21.sp),
        ),
      ),
      if (badge > 0)
        Positioned(
          right: -4.w,
          top: -5.h,
          child: Container(
            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              badge > 9 ? '9+' : '$badge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
    ],
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
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21.sp),
        SizedBox(height: 11.h),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Buy\nshares',
        icon: Icons.trending_up_rounded,
        onTap: () => Get.to(() => const MemberSharePurchasePage()),
      ),
      _QuickAction(
        title: 'Loan\nrequest',
        icon: Icons.request_quote_rounded,
        onTap: () => Get.to(() => const MemberLoanRequestPage()),
      ),
      _QuickAction(
        title: 'Fines',
        icon: Icons.gavel_rounded,
        onTap: () => Get.to(() => const MemberFinesPage()),
      ),
      _QuickAction(
        title: 'Meetings',
        icon: Icons.event_available_rounded,
        onTap: () => Get.to(() => const MemberMeetingsPage()),
      ),
      _QuickAction(
        title: 'Loan\nworkflow',
        icon: Icons.account_tree_rounded,
        onTap: () => Get.to(() => const MemberLoanApplicationsPage()),
      ),
    ];

    return SizedBox(
      height: 92.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: 84.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({required this.meeting});

  final Map<String, dynamic> meeting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = meeting['title']?.toString() ?? 'Group meeting';
    final date = meeting['meetingDate']?.toString() ?? 'Upcoming';
    final time = meeting['startTime']?.toString() ?? '';
    final venue = meeting['location']?.toString() ?? 'Group venue';

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () => Get.to(() => MemberMeetingDetailPage(meeting: meeting)),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$date${time.isEmpty ? '' : ' · $time'} • $venue',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  const _ProfileActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: accent ? AppColors.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accent ? AppColors.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: accent ? Colors.white : AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accent ? Colors.white : colorScheme.onSurface,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.currency});

  final Map<String, dynamic> activity;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colorScheme.outlineVariant),
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
                      color: colorScheme.onSurface,
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
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _money(activity['totalAmount'] ?? activity['amount'], currency),
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12.sp,
        ),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13.sp,
            ),
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
