import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  List<Map<String, dynamic>> customerData = [];
  bool isLoading = true;

  // Fetch customer data from the API
  Future<void> _getCustomers() async {
    final url = Uri.parse('$baseurl/customer');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          customerData = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        print("Error fetching customer data");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching customer data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customers"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show a loading spinner if still fetching data
          : customerData.isEmpty
              ? Center(child: Text("No customers available", style: TextStyle(fontSize: 18))) // Show "No customers available" message
              : ListView.builder(
                  itemCount: customerData.length,
                  itemBuilder: (context, index) {
                    final customer = customerData[index];

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      elevation: 5.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name'] ?? 'No name',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Text('Email: ${customer['email'] ?? 'No email'}'),
                            SizedBox(height: 4.0),
                            Text('Phone: ${customer['phone'] ?? 'No phone'}'),
                            SizedBox(height: 4.0),
                            Text('Address: ${customer['address'] ?? 'No address'}'),
                            SizedBox(height: 4.0),
                            ElevatedButton(
                              onPressed: () {},
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Colors.lightBlueAccent),
                              ),
                              child: Text("Email", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
