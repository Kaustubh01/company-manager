import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendance/comon.dart'; // Assuming you have this for `baseurl`

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  List<Map<String, dynamic>> customerData = [];
  bool isLoading = true;
  final FlutterSecureStorage _storage =
      FlutterSecureStorage(); // For secure storage access

  // Fetch customer data from the API
  Future<void> _getCustomers() async {
    String? businessId = await _storage.read(key: 'business-id');

    if (businessId == null) {
      print("No business ID found in secure storage");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseurl/customers/$businessId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          customerData =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
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
      appBar: AppBar(title: Text("Customers")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : customerData.isEmpty
              ? Center(
                  child: Text("No customers available",
                      style: TextStyle(fontSize: 18)))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 300).floor();
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              crossAxisCount > 1 ? crossAxisCount : 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: customerData.length,
                        itemBuilder: (context, index) {
                          final customer = customerData[index];
                          return _buildCustomerCard(customer);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    customer['name']?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'] ?? 'No name',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      customer['email'] ?? 'No email',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('Phone: ${customer['phone'] ?? 'No phone'}',
                style: TextStyle(fontSize: 14)),
            Text('Address: ${customer['address'] ?? 'No address'}',
                style: TextStyle(fontSize: 14)),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Email", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
