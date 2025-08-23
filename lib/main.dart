import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true; // Default to dark theme

  void toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JimBro',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(onThemeToggle: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.orange,
      fontFamily: 'Trebuchet',
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.orange,
      fontFamily: 'Trebuchet',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black, // True black for OLED
      cardTheme: CardThemeData(
        color: Colors.grey[900], // Very dark grey for cards
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[400],
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isWeeklyView = false; // false = daily, true = weekly

  // Sample data for charts
  final List<FlSpot> caloriesDataDaily = [
    FlSpot(0, 1800),
    FlSpot(1, 2100),
    FlSpot(2, 1950),
    FlSpot(3, 2300),
    FlSpot(4, 1750),
    FlSpot(5, 2050),
    FlSpot(6, 2200),
  ];

  final List<FlSpot> caloriesDataWeekly = [
    FlSpot(0, 14500),
    FlSpot(1, 15200),
    FlSpot(2, 14800),
    FlSpot(3, 15800),
  ];

  final List<FlSpot> weightData = [
    FlSpot(0, 75.2),
    FlSpot(1, 75.0),
    FlSpot(2, 74.8),
    FlSpot(3, 75.1),
    FlSpot(4, 74.9),
    FlSpot(5, 74.7),
    FlSpot(6, 74.5),
  ];

  final double weightGoal = 73.0; // Weight goal in kg

  // Calculate dynamic Y-axis range for weight chart
  double get _weightChartMinY {
    final dataValues = weightData.map((spot) => spot.y).toList();
    final minDataValue = dataValues.reduce((a, b) => a < b ? a : b);
    final minValue = [minDataValue, weightGoal].reduce((a, b) => a < b ? a : b);
    return minValue - 1.0; // Add some padding
  }

  double get _weightChartMaxY {
    final dataValues = weightData.map((spot) => spot.y).toList();
    final maxDataValue = dataValues.reduce((a, b) => a > b ? a : b);
    final maxValue = [maxDataValue, weightGoal].reduce((a, b) => a > b ? a : b);
    return maxValue + 1.0; // Add some padding
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: isWideScreen
          ? _buildWideScreenAppBar(isDark)
          : _buildMobileAppBar(isDark),
      body: _buildBody(isDark),
      bottomNavigationBar: !isWideScreen ? _buildMobileBottomNav() : null,
    );
  }

  PreferredSizeWidget _buildWideScreenAppBar(bool isDark) {
    return AppBar(
      title: Row(children: [_buildLogo(isDark)]),
      actions: [
        _buildNavButton(Icons.home, 'Home', 0, isDark),
        SizedBox(width: 20),
        _buildNavButton(Icons.fitness_center, 'Workouts', 1, isDark),
        SizedBox(width: 20),
        _buildNavButton(Icons.analytics, 'Stats', 2, isDark),
        SizedBox(width: 20),
        _buildNavButton(Icons.settings, 'Settings', 3, isDark),
        SizedBox(width: 20),
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar(bool isDark) {
    return AppBar(
      title: _buildLogo(isDark),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Colors.orange),
          onPressed: () => _onItemTapped(3),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fitness_center, color: Colors.white, size: 24),
        ),
        SizedBox(width: 10),
        Text(
          'JimBro',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    return TextButton.icon(
      onPressed: () => _onItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected
            ? Colors.orange
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.orange
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Workouts',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCaloriesChart(isDark),
          SizedBox(height: 16),
          _buildWeightChart(isDark),
          SizedBox(height: 16),
          _buildPlanOfTheDay(isDark),
          SizedBox(height: 16),
          _buildRecommendations(isDark),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart(bool isDark) {
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
                  'Calories Consumed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                Switch(
                  value: _isWeeklyView,
                  onChanged: (value) {
                    setState(() {
                      _isWeeklyView = value;
                    });
                  },
                  activeThumbColor: Colors.orange,
                  inactiveThumbColor: isDark
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  inactiveTrackColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[300],
                ),
              ],
            ),
            Text(
              _isWeeklyView ? 'Weekly View' : 'Daily View',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: isDark
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
                          if (_isWeeklyView) {
                            const weeks = ['W1', 'W2', 'W3', 'W4'];
                            if (value.toInt() < weeks.length) {
                              return Text(
                                weeks[value.toInt()],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            }
                          } else {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            }
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
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _isWeeklyView
                          ? caloriesDataWeekly
                          : caloriesDataDaily,
                      isCurved: true,
                      color: Colors.orange,
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

  Widget _buildWeightChart(bool isDark) {
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
                    color: isDark ? Colors.white : Colors.grey[800],
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
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: _weightChartMinY,
                  maxY: _weightChartMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
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
                          labelResolver: (line) => '${weightGoal.toStringAsFixed(1)}kg',
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
                              color: isDark
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
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: isDark
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
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData,
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

  Widget _buildPlanOfTheDay(bool isDark) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Plan of the day: Chest',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWorkoutIcon(Icons.fitness_center, 'Bench Press', isDark),
                _buildWorkoutIcon(Icons.trending_up, 'Incline Press', isDark),
                _buildWorkoutIcon(Icons.accessibility_new, 'Push-ups', isDark),
                _buildWorkoutIcon(Icons.sports_gymnastics, 'Dips', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutIcon(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orange, size: 32),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendations(bool isDark) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Today\'s Recommendation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Try to hit 80kg bench today! You were close yesterday with 77.5kg. Focus on proper form and controlled movements.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Handle navigation to different pages
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        // Navigate to Workouts page
        break;
      case 2:
        // Navigate to Stats page
        break;
      case 3:
        // Navigate to Settings page (where theme toggle would be)
        break;
    }
  }
}