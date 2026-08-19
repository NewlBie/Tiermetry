import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/app_typography.dart';
import 'package:tiermetry/core/theme/colors.dart';

class BalancePowerUsageGraph extends StatefulWidget {
  final int overallEfficiency;
  final int avgWhPerMi;

  const BalancePowerUsageGraph({
    required this.overallEfficiency,
    required this.avgWhPerMi,
    super.key,
  });

  @override
  State<BalancePowerUsageGraph> createState() => _BalancePowerUsageGraphState();
}

class _BalancePowerUsageGraphState extends State<BalancePowerUsageGraph> {
  int selectedTab = 0;

  final List<String> tabs = ['Week', 'Month', 'Year'];

  final List<List<FlSpot>> datasets = [
    [
      const FlSpot(0, 0.1),
      const FlSpot(1, 0.4),
      const FlSpot(2, 0.6),
      const FlSpot(3, 0.4),
      const FlSpot(4, 0.8),
      const FlSpot(5, 0.6),
      const FlSpot(6, 0.9),
      const FlSpot(7, 0.2),
    ],
    [
      const FlSpot(0, 0.3),
      const FlSpot(1, 0.6),
      const FlSpot(2, 0.5),
      const FlSpot(3, 0.7),
      const FlSpot(4, 0.9),
      const FlSpot(5, 0.4),
      const FlSpot(6, 0.8),
      const FlSpot(7, 0.5),
    ],
    [
      const FlSpot(0, 0.5),
      const FlSpot(1, 0.7),
      const FlSpot(2, 0.9),
      const FlSpot(3, 0.6),
      const FlSpot(4, 0.85),
      const FlSpot(5, 0.5),
      const FlSpot(6, 0.95),
      const FlSpot(7, 0.4),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.overallEfficiency}% Efficiency',
                style: AppTypography.md,
              ),
              Text('${widget.avgWhPerMi} wh/mi avg.', style: AppTypography.sm),
            ],
          ),
          const SizedBox(height: 12),
          _buildTabBar(),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: LineChart(
                key: ValueKey<int>(selectedTab),
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return _bottomText('11:18');
                          if (value == 7) return _bottomText('15:48');
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: datasets[selectedTab],
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [
                          TiermetryColors.gradientStart,
                          TiermetryColors.gradientEnd,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            TiermetryColors.gradientStart.withValues(
                              alpha: 0.3,
                            ),
                            TiermetryColors.gradientEnd.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Balanced Life Progress',
              style: AppTypography.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomText(String text) => Text(text, style: AppTypography.xs);

  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedTab;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTab = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? TiermetryColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? TiermetryColors.primary
                        : TiermetryColors.textSecondary.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Text(
              tabs[index],
              style: AppTypography.sm.copyWith(
                color:
                    isSelected
                        ? TiermetryColors.primary
                        : TiermetryColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }
}
