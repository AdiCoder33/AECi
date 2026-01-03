import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical_cases/application/clinical_cases_controller.dart';
import '../../home/application/dashboard_providers.dart';
import '../../logbook/data/entries_repository.dart';
import '../../logbook/domain/elog_entry.dart';
import '../../reviewer/data/reviewer_repository.dart';

// Color palette for beautiful charts
const kChartColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Purple
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFF3B82F6), // Blue
  Color(0xFF06B6D4), // Cyan
  Color(0xFFF43F5E), // Rose
];

final surgeryCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final entries = await repo.listEntries(moduleType: moduleRecords, onlyMine: true);
  final counts = <String, int>{};
  for (final entry in entries) {
    final payload = entry.payload;
    final surgery = (payload['surgery'] ??
            payload['learningPointOrComplication'] ??
            '')
        .toString()
        .trim();
    if (surgery.isEmpty) continue;
    counts[surgery] = (counts[surgery] ?? 0) + 1;
  }
  return counts;
});

final oscarScoresProvider =
    FutureProvider.autoDispose<List<ReviewerAssessment>>((ref) async {
  final repo = ref.watch(reviewerRepositoryProvider);
  return repo.listAssessmentsForTrainee();
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logbookStats = ref.watch(fellowDashboardProvider);
    final surgeryCounts = ref.watch(surgeryCountsProvider);
    final ropCases = ref.watch(clinicalCaseListByKeywordProvider('rop'));
    final retinoCases =
        ref.watch(clinicalCaseListByKeywordProvider('retinoblastoma'));
    final oscarScores = ref.watch(oscarScoresProvider);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards Section
              logbookStats.when(
                data: (stats) => _OverviewCardsSection(stats: stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _ErrorCard(message: 'Failed to load overview'),
              ),
              const SizedBox(height: 24),

              // Surgery Distribution Chart
              _ChartCard(
                title: 'Surgery Distribution',
                icon: Icons.pie_chart_rounded,
                child: surgeryCounts.when(
                  data: (counts) {
                    if (counts.isEmpty) {
                      return const _EmptyState(message: 'No surgeries recorded yet');
                    }
                    return _SurgeryPieChart(counts: counts);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => const _EmptyState(message: 'Failed to load data'),
                ),
              ),
              const SizedBox(height: 20),

              // Screening Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'ROP Screening',
                      icon: Icons.remove_red_eye_outlined,
                      color: const Color(0xFF3B82F6),
                      value: ropCases.when(
                        data: (cases) => cases.length.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Retinoblastoma',
                      icon: Icons.visibility_outlined,
                      color: const Color(0xFFEC4899),
                      value: retinoCases.when(
                        data: (cases) => cases.length.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OSCAR Scores Chart
              _ChartCard(
                title: 'OSCAR Performance Scores',
                icon: Icons.bar_chart_rounded,
                child: oscarScores.when(
                  data: (scores) {
                    if (scores.isEmpty) {
                      return const _EmptyState(message: 'No OSCAR scores yet');
                    }
                    return _OscarBarChart(scores: scores);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => const _EmptyState(message: 'Failed to load scores'),
                ),
              ),
              const SizedBox(height: 20),

              // Surgery Breakdown
              _ChartCard(
                title: 'Detailed Surgery Breakdown',
                icon: Icons.list_alt_rounded,
                child: surgeryCounts.when(
                  data: (counts) {
                    if (counts.isEmpty) {
                      return const _EmptyState(message: 'No surgeries recorded yet');
                    }
                    return _SurgeryBreakdownList(counts: counts);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => const _EmptyState(message: 'Failed to load data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Overview Cards Section with gradient backgrounds
class _OverviewCardsSection extends StatelessWidget {
  const _OverviewCardsSection({required this.stats});

  final FellowDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            label: 'Drafts',
            value: stats.drafts,
            icon: Icons.edit_note_rounded,
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientStatCard(
            label: 'Submitted',
            value: stats.submitted,
            icon: Icons.upload_file_rounded,
            gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientStatCard(
            label: 'Approved',
            value: stats.approved,
            icon: Icons.check_circle_rounded,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
      ],
    );
  }
}

class _GradientStatCard extends StatelessWidget {
  const _GradientStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Chart Card Container
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// Stat Card for screening counts
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Error Card Widget
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}

// Beautiful Donut Chart for Surgery Distribution with stats
class _SurgeryPieChart extends StatelessWidget {
  const _SurgeryPieChart({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final merged = _mergeSurgeryCounts(counts);
    final total = _totalSurgeries(counts);
    
    final items = merged.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Row(
          children: [
            // Donut Chart
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _PieChartPainter(
                      items: items,
                      total: total,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Surgeries',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Top 3 Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.take(3).map((item) {
                  final index = items.indexOf(item);
                  final color = kChartColors[index % kChartColors.length];
                  final percentage = ((item.value / total) * 100).toStringAsFixed(0);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${item.value}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        // All items wrapped
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            final index = items.indexOf(item);
            final color = kChartColors[index % kChartColors.length];
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.key}: ${item.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Pie Chart Painter
class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.items,
    required this.total,
  });

  final List<MapEntry<String, int>> items;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    var startAngle = -pi / 2;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = (item.value / total) * 2 * pi;
      final color = kChartColors[i % kChartColors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..lineTo(center.dx, center.dy)
        ..close();

      canvas.drawPath(path, paint);

      // Draw inner circle to create donut effect
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, innerRadius, innerPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => true;
}

// OSCAR Line Chart with trend visualization
class _OscarBarChart extends StatelessWidget {
  const _OscarBarChart({required this.scores});

  final List<ReviewerAssessment> scores;

  @override
  Widget build(BuildContext context) {
    final displayScores = scores.take(10).toList();
    final values = displayScores
        .map((s) => (s.oscarTotal ?? s.score ?? 0).toDouble())
        .toList();
    
    if (values.isEmpty || values.every((v) => v == 0)) {
      return const _EmptyState(message: 'No scores available');
    }

    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);

    return Column(
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.all(20),
          child: CustomPaint(
            size: const Size(double.infinity, 240),
            painter: _LineChartPainter(
              values: values,
              maxValue: maxValue,
              minValue: minValue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChartLegendItem(
              color: const Color(0xFF6366F1),
              label: 'OSCAR Score',
            ),
            const SizedBox(width: 24),
            _ChartLegendItem(
              color: const Color(0xFF10B981),
              label: 'Trend',
              isDashed: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.1),
                const Color(0xFF8B5CF6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Performance trend across ${values.length} assessments',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Line Chart Painter for trend visualization
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
  });

  final List<double> values;
  final double maxValue;
  final double minValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final padding = 50.0;
    final bottomPadding = 60.0;
    final leftPadding = 55.0;
    final chartWidth = size.width - leftPadding - 20;
    final chartHeight = size.height - padding - bottomPadding;
    final valueRange = maxValue - minValue;
    final normalizedRange = valueRange == 0 ? 1 : valueRange;

    // Draw Y-axis label
    final yAxisPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    canvas.save();
    canvas.translate(15, size.height / 2);
    canvas.rotate(-pi / 2);
    
    yAxisPainter.text = const TextSpan(
      text: 'OSCAR Score',
      style: TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
    yAxisPainter.layout();
    yAxisPainter.paint(canvas, Offset(-yAxisPainter.width / 2, 0));
    canvas.restore();

    // Draw X-axis label
    final xAxisPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    xAxisPainter.text = const TextSpan(
      text: 'Case Assessments',
      style: TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
    xAxisPainter.layout();
    xAxisPainter.paint(
      canvas,
      Offset(
        (size.width - xAxisPainter.width) / 2,
        size.height - 20,
      ),
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (var i = 0; i <= 5; i++) {
      final y = padding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - 20, y),
        gridPaint,
      );
    }

    // Draw Y-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (var i = 0; i <= 5; i++) {
      final value = maxValue - (normalizedRange / 5) * i;
      final y = padding + (chartHeight / 5) * i;
      
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Calculate points for line chart
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = leftPadding + (chartWidth / (values.length - 1)) * i;
      final normalizedValue = (values[i] - minValue) / normalizedRange;
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw gradient fill under line
    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, padding + chartHeight);
    for (final point in points) {
      gradientPath.lineTo(point.dx, point.dy);
    }
    gradientPath.lineTo(points.last.dx, padding + chartHeight);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6366F1).withOpacity(0.3),
          const Color(0xFF6366F1).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(gradientPath, gradientPaint);

    // Draw trend line (simple moving average)
    if (points.length > 2) {
      final trendPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final trendPath = Path();
      final windowSize = min(3, points.length);
      
      for (var i = 0; i < points.length; i++) {
        final start = max(0, i - windowSize ~/ 2);
        final end = min(points.length, i + windowSize ~/ 2 + 1);
        var avgY = 0.0;
        
        for (var j = start; j < end; j++) {
          avgY += points[j].dy;
        }
        avgY /= (end - start);
        
        if (i == 0) {
          trendPath.moveTo(points[i].dx, avgY);
        } else {
          trendPath.lineTo(points[i].dx, avgY);
        }
      }
      
      canvas.drawPath(
        _createDashedPath(trendPath, 5, 3),
        trendPaint,
      );
    }

    // Draw main line
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw points and values
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Outer circle (shadow)
      final outerPaint = Paint()
        ..color = const Color(0xFF6366F1).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 8, outerPaint);
      
      // Inner circle
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 5, pointPaint);
      
      // Center dot
      final centerPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 3, centerPaint);

      // Draw value on top of point
      textPainter.text = TextSpan(
        text: values[i].toInt().toString(),
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 20),
      );

      // Draw case number at bottom
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          padding + chartHeight + 8,
        ),
      );
    }
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final dashedPath = Path();
    final dashGapLength = dashLength + gapLength;
    final metrics = source.computeMetrics();
    
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDash = distance + dashLength;
        final nextGap = nextDash + gapLength;
        
        if (nextDash < metric.length) {
          dashedPath.addPath(
            metric.extractPath(distance, nextDash),
            Offset.zero,
          );
        } else {
          dashedPath.addPath(
            metric.extractPath(distance, metric.length),
            Offset.zero,
          );
          break;
        }
        distance = nextGap;
      }
    }
    
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

// Chart Legend Item
class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  final Color color;
  final String label;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? null : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Dashed line painter for legend
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(min(x + 4, size.width), size.height / 2),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

// Surgery Breakdown List
class _SurgeryBreakdownList extends StatelessWidget {
  const _SurgeryBreakdownList({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final merged = _mergeSurgeryCounts(counts);
    final total = _totalSurgeries(counts);
    
    final items = merged.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: items.map((item) {
        final index = items.indexOf(item);
        final color = kChartColors[index % kChartColors.length];
        final percentage = (item.value / total);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Remove old widgets that are no longer needed
class _GridBackground extends StatelessWidget {
  const _GridBackground({required this.child, required this.lineColor});

  final Widget child;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return child; // Simplified, no grid background needed
  }
}

int _totalSurgeries(Map<String, int> counts) {
  var total = 0;
  for (final value in counts.values) {
    total += value;
  }
  return total;
}

Map<String, int> _mergeSurgeryCounts(Map<String, int> counts) {
  const options = [
    'SOR',
    'VH',
    'RRD',
    'SFIOL',
    'MH',
    'Scleral buckle',
    'Belt buckle',
    'ERM',
    'TRD',
    'PPL+PPV+SFIOL',
    'ROP laser',
  ];
  final merged = <String, int>{};
  var other = 0;
  for (final entry in counts.entries) {
    if (options.contains(entry.key)) {
      merged[entry.key] = entry.value;
    } else {
      other += entry.value;
    }
  }
  for (final option in options) {
    merged.putIfAbsent(option, () => 0);
  }
  if (other > 0) {
    merged['Other'] = other;
  }
  return merged;
}
