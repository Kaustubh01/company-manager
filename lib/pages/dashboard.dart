import 'dart:convert';

import 'package:attendance/comon.dart';
import 'package:attendance/graphs/circular_chart.dart';
import 'package:attendance/graphs/line_chart_graph.dart';
import 'package:attendance/pages/customer_page.dart';
import 'package:attendance/pages/employee.dart';
import 'package:attendance/pages/inventory_page.dart';
import 'package:attendance/pages/sales_page.dart';
import 'package:attendance/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;

  // Initialize secure storage
  final _storage = FlutterSecureStorage();
  Future<void> _getSales() async {
    // Read business ID from secure storage
    String? businessId = await _storage.read(key: 'business-id');
    print('buisness id $businessId');
    if (businessId == null) {
      print("Business ID is not available in secure storage.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseurl/sales/$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          print("Sales data is $response.body");
          salesData =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        print("Error fetching sales data: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            color: Colors.white,
          ),
          child: Column(
            children: [
              DrawerHeader(
                // decoration: BoxDecoration(
                //   color: Colors.blue.shade700,
                // ),
                child: Center(
                  child: Text(
                    'BizMaster',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Sales',
                        style: TextStyle(color: Colors.white),
                      ),
                      tileColor: Colors.transparent,
                      hoverColor: Colors.orange.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SalesPage()),
                        );
                      },
                    ),
                    ListTile(
                      title: Text('Employees',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Employee()),
                        );
                      },
                    ),
                    ListTile(
                      title: Text('Customers',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CustomerPage()),
                        );
                      },
                    ),
                    ListTile(
                      title: Text('Inventory',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InventoryPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  tileColor: Colors.orange.shade600,
                  hoverColor: Colors.orange.shade400,
                  onTap: () async {
                    final storage = FlutterSecureStorage();

                    // Clear all stored data
                    await storage.deleteAll();

                    // Optionally, navigate to the login page or home page after logout
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Login()), // Adjust this to your login page
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: salesData.isEmpty
          ? Center(child: Text("No data found"))
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [LineChartGraph(), CircularChart()],
              ),
            ),
    );
  }
}
