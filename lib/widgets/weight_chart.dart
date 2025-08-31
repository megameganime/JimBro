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
  State<WeightChart> createState() => _WeightChartState();
}

// State for WeightChart
class _WeightChartState extends State<WeightChart> {
  double weightGoal = 0.0;
  bool _loading = true;
  bool _showPrompt = false;
  List<WeightEntry> weightData = [];

  @override
  void initState() {
    super.initState();
    _fetchWeightGoal();
    _fetchWeeklyWeight();
  }

  // Fetch weight goal from SharedPreferences
  Future<void> _fetchWeightGoal() async {
    try {
      final goal = await SharedPrefsService.getWeightGoal();
      setState(() {
        weightGoal = goal;
        _loading = false;
        _showPrompt = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _showPrompt = true;
      });
    }
  }

  // getWeeklyWeight from SharedPreferences
  Future<void> _fetchWeeklyWeight() async {
    try {
      final weights = await SharedPrefsService.getWeeklyWeight();
      setState(() {
        weightData = weights;
      });
    } catch (error) {
      // Mock weight data for the past 7 days
      final List<WeightEntry> weightData = List.generate(7, (i) {
        final date = DateTime.now().subtract(Duration(days: 6 - i));
        final weight =
            75.0 + (i * 0.1) - (i % 2 == 0 ? 0.2 : 0.0); // Example weights
        return WeightEntry(date, weight);
      });
    }
  }

  // Convert weight data to FlSpot for the chart
  List<FlSpot> get chartWeights => List.generate(
    weightData.length,
    (i) => FlSpot(i.toDouble(), weightData[i].weight),
  );

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
                  child: GestureDetector(
                    onTap: () {
                      _showWeightGoalInputDialog(context, widget.isDark);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Goal: ${weightGoal.toStringAsFixed(1)}kg',
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
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: _weightChartMinY(weightGoal),
                  maxY: _weightChartMaxY(weightGoal),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: widget.isDark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: widget.isDark
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: weightGoal,
                        color: Colors.green,
                        strokeWidth: 2,
                        dashArray: [8, 4], // Creates dotted line pattern
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.only(right: 8, top: 2),
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (line) =>
                              '${weightGoal.toStringAsFixed(1)}kg',
                        ),
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              color: widget.isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < weightData.length) {
                            final date = weightData[index].date;
                            final formatted = "${date.month}/${date.day}";
                            return Text(
                              formatted,
                              style: TextStyle(
                                color: widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 10,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
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
              'Please enter your current weight and desired goal to see your progress chart.',
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
                  setState(() {
                    // push weight to list of weight per date, if date already has weight, replace it
                    final today = DateTime.now();
                    // Find index of today's entry in weightData
                    final index = weightData.indexWhere(
                      (entry) =>
                          entry.date.year == today.year &&
                          entry.date.month == today.month &&
                          entry.date.day == today.day,
                    );
                    if (index != -1) {
                      // Update today's weight
                      weightData[index] = WeightEntry(today, weight);
                    } else {
                      // Add new entry for today
                      weightData.add(WeightEntry(today, weight));
                    }
                  });
                  await SharedPrefsService.datedWeights(weightData);
                }
                final double? goal = double.tryParse(goalController.text);
                if (goal != null) {
                  await SharedPrefsService.saveWeightGoal(goal);
                  setState(() {
                    weightGoal = goal;
                    _showPrompt = false;
                  });
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
