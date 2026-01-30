import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tiermetry/theme/colors.dart';
import 'package:tiermetry/theme/app_typography.dart';

class BalancePowerUsageGraph extends StatefulWidget {
  final int overallEfficiency;
  final int avgWhPerMi;

  const BalancePowerUsageGraph({
    super.key,
    required this.overallEfficiency,
    required this.avgWhPerMi,
  });

  @override
  State<BalancePowerUsageGraph> createState() => _BalancePowerUsageGraphState();
}

class _BalancePowerUsageGraphState extends State<BalancePowerUsageGraph> {
  int selectedTab = 0;

  final List<String> tabs = ['Week', 'Month', 'Year'];

  final List<List<FlSpot>> datasets = [
    [
      FlSpot(0, 0.1), FlSpot(1, 0.4), FlSpot(2, 0.6), FlSpot(3, 0.4), FlSpot(4, 0.8), FlSpot(5, 0.6), FlSpot(6, 0.9), FlSpot(7, 0.2),
    ],
    [
      FlSpot(0, 0.3), FlSpot(1, 0.6), FlSpot(2, 0.5), FlSpot(3, 0.7), FlSpot(4, 0.9), FlSpot(5, 0.4), FlSpot(6, 0.8), FlSpot(7, 0.5),
    ],
    [
      FlSpot(0, 0.5), FlSpot(1, 0.7), FlSpot(2, 0.9), FlSpot(3, 0.6), FlSpot(4, 0.85), FlSpot(5, 0.5), FlSpot(6, 0.95), FlSpot(7, 0.4),
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
              Text("${widget.overallEfficiency}% Efficiency", style: AppTypography.md),
              Text("${widget.avgWhPerMi} wh/mi avg.", style: AppTypography.sm),
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
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return _bottomText("11:18");
                          if (value == 7) return _bottomText("15:48");
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            TiermetryColors.gradientStart.withValues(alpha: 0.3),
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
            child: Text("Balanced Life Progress", style: AppTypography.subtitle),
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
              color: isSelected ? TiermetryColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? TiermetryColors.primary : TiermetryColors.textSecondary.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Text(
              tabs[index],
              style: AppTypography.sm.copyWith(
                color: isSelected ? TiermetryColors.primary : TiermetryColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }
}
