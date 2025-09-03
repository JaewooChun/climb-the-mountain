import 'package:flutter/material.dart';
import './screens/starting_view.dart'; // Make sure to import your start_mountain.dart file

void main() {
  runApp(const FinancialPeakApp());
}

class FinancialPeakApp extends StatelessWidget {
  const FinancialPeakApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Peak',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Remove the debug banner for a cleaner look
      debugShowCheckedModeBanner: false,
      // Set StartMountainView as the home screen
      home: const StartMountainView(),
      // You can add routes here for navigation later
      routes: {
        '/start': (context) => const StartMountainView(),
        // Add more routes as you build your game
        // '/dashboard': (context) => DashboardScreen(),
        // '/mountain-climb': (context) => MountainClimbScreen(),
      },
    );
  }
}
