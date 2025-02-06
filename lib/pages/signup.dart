import 'package:attendance/comon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _createAccount(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String? businessId = await _storage.read(key: 'business-id');

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseurl/business/$businessId/employees/create');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': 'owner',
          'department': 'admin',
          'password': password
        }),
      );

      if (response.statusCode == 201) {
        await _storage.write(key: 'email', value: email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );
        Navigator.pop(context);
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(
            errorResponse['error'] ?? "Error creating account. Try again.");
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
      backgroundColor: Colors.grey[200], // Light background
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: Colors.purple, // AppBar color
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
                screenWidth > 600 ? 80.0 : 24.0, // More margin on large screens
            vertical: 32.0,
          ),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 400, // Maximum width of the form
                  maxHeight: 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Create Account",
                      style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'OpenSans'),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Your Email',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Your Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _createAccount(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple, // Button color
                              foregroundColor: Colors.white, // Text color
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 40), // Increased padding
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Create Account"),
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
