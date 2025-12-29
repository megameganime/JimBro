import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jim_bro/local_storage/shared_prefs.dart';

// Weight entry model
class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry(this.date, this.weight);
}

// WeightChart widget
class WeightChart extends StatefulWidget {
  final bool isDark;

  const WeightChart({super.key, required this.isDark});

  @override
  State<WeightChart> createState() => WeightChartState();
}

// State for WeightChart
class WeightChartState extends State<WeightChart> {
  double weightGoal = 0.0; // internal storage in kg
  bool _loading = true;
  bool _showPrompt = false;
  bool _useLbs = false; // display preference
  List<WeightEntry> weightData = [];

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    // load unit preference and data
    await _fetchUnitPref();
    await _fetchWeightGoal();
    await _fetchWeeklyWeight();
  }

  Future<void> _fetchUnitPref() async {
    final useLbs = await SharedPrefsService.getUseLbs();
    if (mounted) setState(() => _useLbs = useLbs);
  }

  // Fetch weight goal from SharedPreferences (stored as kg)
  Future<void> _fetchWeightGoal() async {
    try {
      final goal = await SharedPrefsService.getWeightGoal();
      if (mounted) {
        setState(() {
        weightGoal = goal; // keep as kg internally
        _loading = false;
        _showPrompt = false;
      });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
        _loading = false;
        _showPrompt = true;
      });
      }
    }
  }

  // getWeeklyWeight from SharedPreferences (assumed returns List<WeightEntry> with kg)
  Future<void> _fetchWeeklyWeight() async {
    try {
      final weights = await SharedPrefsService.getWeeklyWeight();
      if (mounted) {
        setState(() {
        weightData = weights;
      });
      }
    } catch (error) {
      // fallback/mock weight data for the past 7 days
      // final List<WeightEntry> weightData = List.generate(7, (i) {
      //   final date = DateTime.now().subtract(Duration(days: 6 - i));
      //   final weight =
      //       75.0 + (i * 0.1) - (i % 2 == 0 ? 0.2 : 0.0); // Example weights
      //   return WeightEntry(date, weight);
      // });
      // if (mounted) {
      //   setState(() {
      //     this.weightData = weightData;
      //   });
      // }
    }
  }

  // Public refresh to be called by parent route observer
  Future<void> refresh() async {
    setState(() => _loading = true);
    await _fetchUnitPref();
    await _fetchWeightGoal();
    await _fetchWeeklyWeight();
    if (mounted) setState(() => _loading = false);
  }

  // Convert internal WeightEntry list to FlSpot using displayed units.
  List<FlSpot> get chartWeights {
    // ensure we have 7 days (or available), map index -> weight (converted if needed)
    final list = weightData;
    return List.generate(list.length, (i) {
      final displayY = _useLbs ? SharedPrefsService.kgToLbs(list[i].weight) : list[i].weight;
      return FlSpot(i.toDouble(), displayY);
    });
  }

  // Helper to format axis labels in display units
  String _formatAxisLabel(double value) {
    // value is already in display units (because chartWeights converted)
    return value.toStringAsFixed(1);
  }

  double _weightChartMinY(double? wg) {
    final dataValues = chartWeights.map((spot) => spot.y).toList();
    final minDataValue = dataValues.reduce((a, b) => a < b ? a : b);
    final minValue = [
      minDataValue,
      wg ?? minDataValue,
    ].reduce((a, b) => a < b ? a : b);
    return minValue - 1.0; // Add some padding
  }

  double _weightChartMaxY(double? wg) {
    final dataValues = chartWeights.map((spot) => spot.y).toList();
    final maxDataValue = dataValues.reduce((a, b) => a > b ? a : b);
    final maxValue = [
      maxDataValue,
      wg ?? maxDataValue,
    ].reduce((a, b) => a > b ? a : b);
    return maxValue + 1.0; // Add some padding
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_showPrompt) {
      return _buildWeightGoalPrompt(widget.isDark);
    }

    // Convert goal to display units (chartWeights are already in display units)
    final double? goalDisplay = weightGoal == 0.0 // if goal is 0, dont do anything
        ? null
        : (_useLbs ? SharedPrefsService.kgToLbs(weightGoal) : weightGoal);

    // use the helper functions so they are not unused
    final minY = chartWeights.isNotEmpty ? _weightChartMinY(goalDisplay) : 0.0;
    final maxY = chartWeights.isNotEmpty ? _weightChartMaxY(goalDisplay) : 10.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showWeightGoalInputDialog(context, widget.isDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, color: Colors.green, size: 14),
                          SizedBox(width: 8),
                          Text(
                            // display the goal converted if needed
                            SharedPrefsService.formatWeight(weightGoal, useLbs: _useLbs, decimals: 1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  // draw a dashed green horizontal line at the goal if set
                  extraLinesData: ExtraLinesData(
                    horizontalLines: goalDisplay != null
                        ? [
                            HorizontalLine(
                              y: goalDisplay,
                              color:  Colors.green,
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                // show formatted goal using current unit preference
                                labelResolver: (hl) => SharedPrefsService.formatWeight(
                                    weightGoal, useLbs: _useLbs, decimals: 1),
                              ),
                            ),
                          ]
                        : [],
                  ),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(_formatAxisLabel(value));
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // ask fl_chart to place labels at integer steps
                        getTitlesWidget: (value, meta) {
                          // Only show a label for exact integer indices -> avoids duplicate labels
                          final rounded = value.roundToDouble();
                          if ((value - rounded).abs() > 0.001) return const SizedBox.shrink();

                          final idx = rounded.toInt();
                          if (idx >= 0 && idx < weightData.length) {
                            final date = weightData[idx].date;
                            return Text('${date.month}/${date.day}',
                                style: TextStyle(
                                  color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                                  fontSize: 10,
                                ));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartWeights,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // First card you see when no weights are set at all, gives button to input today's weight and goal
  Widget _buildWeightGoalPrompt(bool isDark) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    return Card(
      child: Container(
        height: 260,
        alignment: Alignment.center,
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWideScreen) ...[
              Icon(Icons.flag, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Set Your Weight Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
            ],
            Text(
              'Enter your current weight and desired goal to see your progress chart.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.edit),
              label: Text('Input Weight & Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showWeightGoalInputDialog(context, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightGoalInputDialog(BuildContext context, bool isDark) {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController goalController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text('Enter Weight & Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Current Weight (kg)'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: goalController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Weight Goal (kg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                final double? weight = double.tryParse(weightController.text);
                if (weight != null) {
                    final today = DateTime.now();
                    _showPrompt = false;
                  await SharedPrefsService.upsertDatedWeight(WeightEntry(today, weight));
                }
                final double? goal = double.tryParse(goalController.text);
                if (goal != null) {
                  await SharedPrefsService.saveWeightGoal(goal);
                  setState(() {
                    weightGoal = goal;
                    _showPrompt = false;
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
