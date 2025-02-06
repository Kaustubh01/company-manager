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

  // Group employees by department
  Map<String, List<Map<String, dynamic>>> groupedEmployees = {};

 Future<void> _showAddEmployeeDialog() async {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController departmentController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Add Employee"),
        content: SingleChildScrollView(  // Make the content scrollable
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,  // Limit the height of the dialog
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
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
                    controller: departmentController,
                    decoration: InputDecoration(labelText: "Department"),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: "Password"),
                    keyboardType: TextInputType.visiblePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _addEmployee(
                nameController.text,
                emailController.text,
                roleController.text,
                departmentController.text,
                passwordController.text,
              );
              _getEmployees();
              Navigator.of(context).pop();
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}



  Future<void> _addEmployee(String name, String email, String role, String department, String password) async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees/create');

    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
          'department': department,
          'password': password// Include department in the body
        }));
    if (response.statusCode == 201) {
      print("Employee added successfully");
      _getEmployees();
    } else {
      print("Failed to add employee");
    }
  }

  Future<void> _getEmployees() async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      List<dynamic> employees = jsonDecode(response.body);
      setState(() {
        _employees = employees.map((e) => Map<String, dynamic>.from(e)).toList();

        // Group employees by department
        groupedEmployees = {};
        for (var employee in _employees) {
          String department = employee['department'] ?? 'Unknown';
          if (!groupedEmployees.containsKey(department)) {
            groupedEmployees[department] = [];
          }
          groupedEmployees[department]!.add(employee);
        }
      });
      print("Employees fetched successfully: $employees");
    } else {
      print("Failed to fetch employees");
    }
  }

  @override
  void initState() {
    super.initState();
    _getEmployees();
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
            icon: Icon(Icons.qr_code),
          )
        ],
      ),
      body: Center(
        child: _employees.isEmpty
            ? ElevatedButton(
                onPressed: _showAddEmployeeDialog,
                child: Text("Add Employee"),
              )
            : ListView.builder(
                itemCount: groupedEmployees.keys.length,
                itemBuilder: (context, index) {
                  String department = groupedEmployees.keys.elementAt(index);
                  List<Map<String, dynamic>> employeesInDepartment =
                      groupedEmployees[department]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department Title
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          department,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // List of employees in this department
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: employeesInDepartment.length,
                        itemBuilder: (context, empIndex) {
                          return ListTile(
                            title: Text(employeesInDepartment[empIndex]['name']),
                            subtitle: Text(employeesInDepartment[empIndex]['role']),
                            onTap: () {
                              int empId = employeesInDepartment[empIndex]['id'];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewEmployeeDetails(
                                    id: empId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: _employees.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddEmployeeDialog,
              tooltip: 'Add Employee',
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
