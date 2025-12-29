import 'package:flutter/material.dart';
import 'package:jim_bro/pages/home_page.dart';
import 'package:jim_bro/pages/settings_page.dart';
import 'package:jim_bro/pages/weight_edit_page.dart';
import 'package:jim_bro/pages/workouts_page.dart';
import 'package:provider/provider.dart';
import 'package:jim_bro/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  ) ;
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JimBro',
      theme: Provider.of<ThemeProvider>(context).changeThemeDataTo,
      home: const HomePage(),
      navigatorObservers: [routeObserver], // register observer
      routes: {
      '/settings': (ctx) => SettingsPage(),
      '/weight-edit': (ctx) => WeightEditPage(),
      '/workouts': (ctx) => WorkoutsPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
