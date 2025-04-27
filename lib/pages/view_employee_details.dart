import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ViewEmployeeDetails extends StatefulWidget {
  final int id;
  const ViewEmployeeDetails({super.key, required this.id});

  @override
  State<ViewEmployeeDetails> createState() => _ViewEmployeeDetailsState();
}

class _ViewEmployeeDetailsState extends State<ViewEmployeeDetails> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Map<String, dynamic>? employee;
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _getEmployee(widget.id);
    _getTasks(widget.id);
  }

  Future<void> _getTasks(int id) async {
    final url = Uri.parse('$baseurl/tasks?employeeId=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          tasks = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        print("Error loading tasks");
      }
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  Future<void> _getEmployee(int id) async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees/search-id?id=$id');
    try {
      final response =
      await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        setState(() {
          employee = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        print("Failed to fetch employee: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Error fetching employee: $e");
    }
  }

  Future<void> _updateSalary(double newSalary) async {
    String? businessId = await _storage.read(key: 'business-id');
    final url = Uri.parse('$baseurl/business/$businessId/employees/update-salary');
    try {
      final response = await http.put(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': widget.id,
            'newSalary': newSalary,
          }));

      if (response.statusCode == 200) {
        setState(() {
          employee!['salary'] = newSalary;
        });
        print("Salary updated successfully");
      } else {
        print("Failed to update salary: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating salary: $e");
    }
  }

  Future<double?> _showSalaryUpdateDialog() {
    TextEditingController salaryController = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Salary"),
          content: TextField(
            controller: salaryController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: "New Salary"),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  double? newSalary = double.tryParse(salaryController.text);
                  if (newSalary != null) {
                    Navigator.of(context).pop(newSalary);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a valid salary")));
                  }
                },
                child: const Text("Update"))
          ],
        );
      },
    );
  }

  Future<void> _updateTaskStatus(int taskId, String status) async {
    final url = Uri.parse('$baseurl/tasks/update-status');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'taskId': taskId, 'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated to "$status"')),
        );
        // Refresh the tasks list after updating the status
        await _getTasks(widget.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task status')),
        );
      }
    } catch (e) {
      print("Error updating task status: $e");
    }
  }

  void _showTaskDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController dueDateController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: dueDateController,
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                      DateFormat("yyyy-MM-ddTHH:mm:ss").format(pickedDate);
                      dueDateController.text = formattedDate;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel")),
              ElevatedButton(
                  onPressed: () async {
                    String title = titleController.text;
                    String description = descriptionController.text;
                    String dueDate = dueDateController.text;

                    if (dueDate.isNotEmpty) {
                      DateTime parsedDate = DateTime.parse(dueDate);
                      dueDate = parsedDate.toUtc().toIso8601String();
                    }

                    final url = Uri.parse('$baseurl/tasks');

                    final response = await http.post(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        "employeeId": widget.id,
                        "title": title,
                        "description": description,
                        "dueDate": dueDate,
                      }),
                    );

                    if (response.statusCode == 201) {
                      print('task created successfully');
                      _getTasks(widget.id);
                    } else {
                      print('failed to create task');
                    }

                    Navigator.pop(context);
                  },
                  child: Text("Add"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Details"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : hasError || employee == null
            ? const Text("Failed to load employee details.")
            : _buildEmployeeDetails(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTaskDialog(context);
        },
        backgroundColor: Colors.blue.shade500,
        child: Icon(Icons.add_task, color: Colors.white),
      ),
    );
  }

  Widget _buildEmployeeDetails() {
    String lastAttendance = employee!["lastAttendanceRecorded"] ?? "";
    DateTime serverDate = DateTime.tryParse(lastAttendance) ?? DateTime(2000);
    String serverDateFormatted = DateFormat('yyyy-MM-dd').format(serverDate);
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isPresentToday = serverDateFormatted == today;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee!["name"],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(employee!["role"],
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(employee!["email"],
                      style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
              CircleAvatar(
                radius: 10,
                backgroundColor: isPresentToday ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text("Salary"),
            subtitle: Text(employee!["salary"].toString()),
            onTap: () async {
              double? newSalary = await _showSalaryUpdateDialog();
              if (newSalary != null) {
                _updateSalary(newSalary);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.task_alt, color: Colors.pink),
            title: const Text("Completed Tasks"),
            subtitle: Text(tasks.where((t) => t["status"] == "completed").length.toString()),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in, color: Colors.purple),
            title: const Text("Assigned Tasks"),
            subtitle: Text(tasks.length.toString()),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text("Attendance"),
            subtitle: Text(employee!["attendance"].toString()),
          ),
          ListTile(
            leading: const Icon(Icons.home_work, color: Colors.red),
            title: const Text("Total Leaves"),
            subtitle: Text(employee!["leaves"].toString()),
          ),
          const SizedBox(height: 16),
          const Text("Tasks", style: TextStyle(fontSize: 18)),
          const Divider(thickness: 1),
          if (tasks.isEmpty)
            const Text("No tasks available.")
          else
            ...tasks.map((task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(task["title"]),
                leading: const Icon(Icons.task),
                subtitle: Text("Status: ${task["status"]}"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Title: ${task["title"]}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(task["description"] ?? ""),
                          const SizedBox(height: 8),
                          Text("Due Date: ${task["dueDate"] ?? "None"}"),
                          const SizedBox(height: 8),
                          Text("Assigned On: ${task["assignedOn"] ?? "None"}"),
                        ],
                      ),
                      actions: [
                        if (task["status"] != "COMPLETED")
                          TextButton(
                            onPressed: () {
                              _updateTaskStatus(task["id"], "COMPLETED");
                              Navigator.pop(context);
                            },
                            child: const Text("Mark as Completed"),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )),
        ],
      ),
    );
  }
}
