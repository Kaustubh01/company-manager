import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:attendance/graphs/data/chart_column_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class LineChartGraph extends StatefulWidget {
  const LineChartGraph({super.key});

  @override
  State<LineChartGraph> createState() => _LineChartGraphState();
}

class _LineChartGraphState extends State<LineChartGraph> {
  List<Map<String, dynamic>> salesData = [];

  Future<void> _getSales() async {
    final url = Uri.parse('$baseurl/sales');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          salesData = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        print("Error fetching sales data");
      }
    } catch (e) {
      print("Error fetching sales data: $e");
    }
  }

  final List<ChartColumnData> chartData = <ChartColumnData>[
    ChartColumnData("Mon", 0, 1),
    ChartColumnData("Tue", 0.3, 5),
    ChartColumnData("Wed", 0.3, 3),
    ChartColumnData("Thu", 0.3, 6),
    ChartColumnData("Fri", 0.3, 0),
    ChartColumnData("Sat", 0.3, 0),
    ChartColumnData("Sun", 0.3, 2),
  ];

  @override
  void initState() {
    super.initState();
    _getSales();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sales",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 27,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Total Sales",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SfCartesianChart(
                  plotAreaBackgroundColor: Colors.white,
                  margin: EdgeInsets.all(0),
                  borderColor: Colors.white,
                  borderWidth: 0,
                  plotAreaBorderWidth: 0,
                  enableSideBySideSeriesPlacement: false,
                  primaryXAxis: CategoryAxis(
                    axisLine: AxisLine(width: 0.5),
                    majorGridLines: MajorGridLines(width: 0),
                    majorTickLines: MajorTickLines(width: 0),
                    crossesAt: 0,
                  ),
                  primaryYAxis: NumericAxis(
                    isVisible: false,
                    minimum: 0,
                    maximum: 10,
                    interval: 1,
                  ),
                  series: <CartesianSeries<ChartColumnData, String>>[
                    ColumnSeries<ChartColumnData, String>(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      dataSource: chartData,
                      width: 0.5,
                      color: Colors.blue.shade500,
                      xValueMapper: (ChartColumnData data, _) => data.x,
                      yValueMapper: (ChartColumnData data, _) => data.y1,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Total Customers",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "12",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Orders Placed",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "20",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],

      
    );
  }
}