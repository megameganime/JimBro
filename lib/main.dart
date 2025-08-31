import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jim_bro/widgets/weight_chart.dart' show WeightChart;

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
        selectedItemColor: Colors.indigoAccent[700],
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
        selectedItemColor: Colors.indigoAccent[700],
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

  @override
  void initState() {
    super.initState();
  }

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
          icon: Icon(Icons.settings, color: Colors.indigoAccent[700]),
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
            color: Colors.indigoAccent[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fitness_center, color: Colors.white, size: 24),
        ),
        SizedBox(width: 10),
        Text(
          'JimBro',
          style: TextStyle(
            color: Colors.indigoAccent[700],
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
            ? Colors.indigoAccent[700]
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.indigoAccent[700]
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
          WeightChart(isDark: isDark),
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
                  activeThumbColor: Colors.indigoAccent[700],
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
                      color: Colors.indigoAccent[700],
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
          child: Icon(icon, color: Colors.indigoAccent[700], size: 32),
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
                Icon(
                  Icons.lightbulb,
                  color: Colors.indigoAccent[700],
                  size: 24,
                ),
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
      case 0: // Home
        // Home - already here
        break;
      case 1: // Workouts
        // Navigate to Workouts page
        break;
      case 2: // Stats
        // Navigate to Stats page
        break;
      case 3: // Settings
        // Navigate to Settings page (where theme toggle would be)
        break;
    }
  }
}
