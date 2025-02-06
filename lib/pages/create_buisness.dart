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

  bool _isLoading = false; // Loading indicator

  Future<void> _createBusiness(String name, String type) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$baseurl/business/create'); // Fixed typo
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'type': type}),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final String businessId = responseData['id'].toString();
        print(businessId);

        // Store business details securely
        await _storage.write(key: 'business-id', value: businessId);
        await _storage.write(key: 'business-name', value: name);
        await _storage.write(key: 'business-type', value: type);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business created successfully!')),
        );

        // Navigate to Signup page
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Create Business",
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessTypeController,
              decoration: const InputDecoration(labelText: 'Business Type'),
            ),
            const SizedBox(height: 24),
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
                    child: const Text("Create Business"),
                  ),
          ],
        ),
      ),
    );
  }
}
