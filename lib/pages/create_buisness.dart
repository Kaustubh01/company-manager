import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:attendance/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CreateBusiness extends StatefulWidget {
  const CreateBusiness({super.key});

  @override
  State<CreateBusiness> createState() => _CreateBusinessState();
}

class _CreateBusinessState extends State<CreateBusiness> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createBusiness(String name, String type) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$baseurl/business/create');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'type': type}),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final String businessId = responseData['id'].toString();

        await _storage.write(key: 'business-id', value: businessId);
        await _storage.write(key: 'business-name', value: name);
        await _storage.write(key: 'business-type', value: type);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business created successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Signup()),
        );
      } else {
        _showErrorDialog("Failed to create business. Please try again.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? 80.0 : 24.0,
            vertical: 32.0,
          ),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "Create Business",
                      style: TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _businessTypeController,
                      decoration: InputDecoration(
                        labelText: 'Business Type',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () {
                              final name = _businessNameController.text.trim();
                              final type = _businessTypeController.text.trim();
                              if (name.isNotEmpty && type.isNotEmpty) {
                                _createBusiness(name, type);
                              } else {
                                _showErrorDialog("Please fill in all fields.");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Create Business",
                                style: TextStyle(fontSize: 18)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
