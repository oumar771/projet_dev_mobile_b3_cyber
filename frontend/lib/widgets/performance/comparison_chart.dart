import 'package:flutter/material.dart';
import '../../models/performance.dart';

class ComparisonChart extends StatelessWidget {
  final List<Performance> performances;

  const ComparisonChart({super.key, required this.performances});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performances', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...performances.map((perf) => ListTile(
              title: Text('${perf.distance.toStringAsFixed(1)} km'),
              subtitle: Text('${perf.formattedDuration} - ${perf.avgSpeed.toStringAsFixed(1)} km/h'),
              trailing: Text(perf.pace),
            )),
          ],
        ),
      ),
    );
  }
}
