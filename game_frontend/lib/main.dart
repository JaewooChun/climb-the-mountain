import 'package:flutter/material.dart';
import './screens/views/view_0.dart'; // Initial view that players see

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
      // Set View0 as the home screen
      home: const View0(),
    );
  }
}
