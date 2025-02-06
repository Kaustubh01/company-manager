import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class CircularChart extends StatelessWidget {
  const CircularChart({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> Labels = {
      'Repeating Customers': Colors.blue.shade500,
      'New Customers': Colors.grey
    };

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(8 * 1.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Text(
                'Customer Retention',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 220,
                      child: SfRadialGauge(
                        axes: [
                          RadialAxis(
                            labelOffset: 0,
                            pointers: [
                              RangePointer(
                                value: 20,
                                cornerStyle: CornerStyle.bothCurve,
                                color: Colors.blue.shade500,
                                width: 30,
                              ),
                            ],
                            axisLineStyle: AxisLineStyle(
                              thickness: 30,
                            ),
                            startAngle: 130,
                            endAngle: 410, // Adjusted end angle
                            showLabels: false,
                            showTicks: false,
                            annotations: [
                              GaugeAnnotation(
                                widget: Text(
                                  '77%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                      color: Colors.grey),
                                ),
                                positionFactor: 0.2,
                              )
                            ],
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: Labels.entries
                        .map((entry) => labelsChart(entry.key, entry.value))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget labelsChart(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            height: 15,
            width: 15,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}