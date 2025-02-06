import 'dart:convert';

import 'package:attendance/comon.dart';
import 'package:attendance/pages/qr_scanner.dart';
import 'package:attendance/pages/view_employee_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Employee extends StatefulWidget {
  const Employee({super.key});

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _employees = [];


  Future<void> _showAddEmployeeDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController roleController = TextEditingController();
    TextEditingController departmentController = TextEditingController(); // Added department controller

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Add Employee"),
            content: SizedBox(
              height: 240, // Increased height to fit department field
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(labelText: "Role"),
                  ),
                  TextField(
                    controller: departmentController, // Department input
                    decoration: InputDecoration(labelText: "Department"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel")),
              ElevatedButton(
                  onPressed: () {
                    _addEmployee(
                      nameController.text,
                      emailController.text,
                      roleController.text,
                      departmentController.text, // Pass department field
                    );
                    _getEmployees();
                    Navigator.of(context).pop();
                  },
                  child: Text("Add"))
            ],
          );
        });
  }

  Future<void> _addEmployee(String name, String email, String role, String department) async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees/create');

    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
          'department': department, // Include department in the body
        }));
    if (response.statusCode == 201) {
      print("Employee added successfully");
    } else {
      print("Failed to add employee");
    }
  }

  Future<void> _getEmployees() async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees'); // Adjust URL if needed
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      List<dynamic> employees = jsonDecode(response.body);
      setState(() {
        _employees =
            employees.map((e) => Map<String, dynamic>.from(e)).toList();
      });
      print("Employees fetched successfully: $employees");
    } else {
      print("Failed to fetch employees");
    }
  }

  @override
  void initState() {
    super.initState();
    _getEmployees(); // Fetch employees when the page is opened
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Employees"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => QrScanner()),
                  );
                },
                icon: Icon(Icons.qr_code))
          ],
        ),
        body: Center(
            child: _employees.isEmpty
                ? ElevatedButton(
                    onPressed: _showAddEmployeeDialog,
                    child: Text("Add Employee"))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_employees[index]['name']),
                        subtitle: Text(_employees[index]['role']),
                        onTap: () {
                          int empId = _employees[index]['id'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ViewEmployeeDetails(
                                      id: empId,
                                    )),
                          );
                        },
                      );
                    })),
        floatingActionButton: _employees.isNotEmpty
            ? FloatingActionButton(
                onPressed: _showAddEmployeeDialog,
                tooltip: 'Add Employee',
                child: Icon(Icons.add),
              )
            : null);
  }
}
