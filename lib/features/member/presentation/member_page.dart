import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
      final greeting = TokenStorage.getGreetingForTime(
        DateTime.now().hour,
        controller.memberName.value,
      );

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
                  onTap: () => Get.snackbar(
                    'Notifications',
                    'No new alerts right now.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
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
            _SectionTitle(title: 'Share history', action: 'This year'),
            SizedBox(height: 12.h),
            _ContributionChart(
              points: controller.shareLedger
                  .map(
                    (entry) => {
                      'month': (entry['transactionDate'] ?? '')
                          .toString()
                          .split('T')
                          .first,
                      'amount': _number(entry['totalAmount']),
                    },
                  )
                  .toList(),
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
  const _ProfileView({required this.controller});

  final MemberController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.border),
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
                    color: AppColors.textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  controller.memberProfile['role']?.toString() ??
                      'Member profile',
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
            label: 'Add contribution',
            icon: Icons.add_circle_outline_rounded,
            onTap: () => Get.to(() => const MemberContributionPage()),
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Add\ncontribution',
        icon: Icons.add_circle_rounded,
        onTap: () => Get.snackbar(
          'Contribution',
          'Contribution entry is ready to be added.',
        ),
      ),
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
        title: 'Meetings',
        icon: Icons.event_available_rounded,
        onTap: () => Get.to(() => const MemberMeetingsPage()),
      ),
    ];

    return SizedBox(
      height: 92.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
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
                color: AppColors.textPrimary,
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
    final title = meeting['title']?.toString() ?? 'Group meeting';
    final date = meeting['date']?.toString() ?? 'Upcoming';
    final venue = meeting['venue']?.toString() ?? 'Group venue';

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
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
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$date • $venue',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: accent ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accent ? AppColors.primary : AppColors.border,
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
                    color: accent ? Colors.white : AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent ? Colors.white : AppColors.textSecondary,
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
