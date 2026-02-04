import 'package:flutter/material.dart';
import 'price_change_chart.dart';
import 'land_price_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Charts Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'system-ui',
      ),
      home: const ChartsPage(),
    );
  }
}

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Charts Demo'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Land Price Chart (charts2.tsx equivalent)
                Card(
                  elevation: 2,
                  child: LandPriceChart(),
                ),
                SizedBox(height: 48),
                // Price Change Chart (charts.tsx equivalent)
                Card(
                  elevation: 2,
                  child: PriceChangeChart(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
