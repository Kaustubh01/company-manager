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
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(child: Icon(Icons.flash_on)),
            ListTile(
              title: Text('Sales'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesPage()),
                );
              },
            ),
            ListTile(
              title: Text('Employees'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Employee()),
                );
              },
            ),
            ListTile(
              title: Text('Customers'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerPage()),
                );
              },
            ),
            ListTile(
              title: Text('Inventory'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InventoryPage()),
                );
              },
            ),
            // Add the logout button at the bottom
            ListTile(
              title: Text('Logout'),
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
          ],
        ),
      ),
      body: salesData.isEmpty ? Center(child: Text("No data found")) : SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [LineChartGraph(), CircularChart()],
        ),
      ),
    );
  }
}
