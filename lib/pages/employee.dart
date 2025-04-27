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
  Map<String, List<Map<String, dynamic>>> groupedEmployees = {};

  Future<void> _getEmployees() async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees');
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      List<dynamic> employees = jsonDecode(response.body);
      setState(() {
        _employees =
            employees.map((e) => Map<String, dynamic>.from(e)).toList();
        groupedEmployees = {};

        for (var employee in _employees) {
          String department = employee['department'] ?? 'Unknown';
          groupedEmployees.putIfAbsent(department, () => []).add(employee);
        }
      });
    }
  }

  Future<void> _addEmployee(String name, String email, String role,
      String department, String password) async {
    // Print the data coming from the dialog box for debugging purposes
    print("Employee Details:");
    print("Name: $name");
    print("Email: $email");
    print("Role: $role");
    print("Department: $department");
    print("Password: $password");

    // Proceed to add employee to the database
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "email": email,
        "role": role,
        "department": department,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      _getEmployees();
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController emailController = TextEditingController();
        TextEditingController roleController = TextEditingController();
        TextEditingController departmentController = TextEditingController();
        TextEditingController passwordController = TextEditingController();

        return AlertDialog(
          title: Text(
            "Add Employee",
            style: TextStyle(color: Colors.orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Name"),
          keyboardType: TextInputType.text,
              ),
              TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: "Email"),
          keyboardType: TextInputType.emailAddress,
              ),
              TextField(
          controller: roleController,
          decoration: InputDecoration(labelText: "Role"),
          keyboardType: TextInputType.text,
              ),
              TextField(
          controller: departmentController,
          decoration: InputDecoration(labelText: "Department"),
          keyboardType: TextInputType.text,
              ),
              TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: "Password"),
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue.shade500),
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
          Navigator.pop(context);
              },
              child: Text("Add"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade500,
                foregroundColor: Colors.white
                ),
            ),
          ],
        );
      },
    );
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
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => QrScanner()),
              );
            },
            icon: Icon(Icons.qr_code),
          ),
        ],
      ),
      body: _employees.isEmpty
          ? Center(
              child: Card(
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Add Employee",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: groupedEmployees.entries.map((entry) {
                  String department = entry.key;
                  List<Map<String, dynamic>> employeesInDepartment =
                      entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          department,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount =
                              (constraints.maxWidth / 250).floor();
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  crossAxisCount > 1 ? crossAxisCount : 1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: employeesInDepartment.length,
                            itemBuilder: (context, empIndex) {
                              var employee = employeesInDepartment[empIndex];
                              return _buildEmployeeCard(employee);
                            },
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        tooltip: 'Add Employee',
        backgroundColor: Colors.blue.shade500,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return GestureDetector(
      onTap: () {
        int empId = employee['id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEmployeeDetails(id: empId),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  employee['name'][0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    employee['role'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
