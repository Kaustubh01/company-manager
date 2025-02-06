import 'dart:convert';
import 'dart:typed_data';
import 'package:attendance/comon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanner extends StatelessWidget {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  QrScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: true,
        ),
        onDetect: (capture) async {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;

          // Check if barcodes are detected
          if (barcodes.isEmpty) {
            print("No barcodes found.");
            return;
          }

          // Process the first barcode
          final String? rawValue = barcodes.first.rawValue;
          if (rawValue == null || rawValue.isEmpty) {
            print("Invalid barcode or empty raw value.");
            return;
          }

          // Attempt to decode the raw value
          Map<String, dynamic> idMap = {};
          try {
            idMap = jsonDecode(rawValue);
            print("Decoded data: $idMap");
          } catch (e) {
            print("Failed to decode barcode data: $e");
            return;
          }

          // Ensure 'name', 'email', and 'employeeId' are present in the decoded map
          if (!idMap.containsKey("name") || !idMap.containsKey("email") || !idMap.containsKey("employeeId")) {
            print("Missing required fields in barcode data.");
            return;
          }

          String name = idMap["name"].toString(); // Ensure it's a string
          String email = idMap["email"].toString(); // Ensure it's a string
          String employeeId = idMap["employeeId"].toString(); // Ensure it's a string

          // Retrieve the businessId from secure storage
          String? businessId = await _storage.read(key: 'business-id');
          print("Business ID: $businessId");  // Print business ID from storage
          if (businessId == null) {
            print("Business ID not found.");
            return;
          }

          // Update attendance
          final url = Uri.parse('$baseurl/business/$businessId/employees/update-attendance');
          final response = await http.put(url,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({"id": employeeId}));

          if (response.statusCode == 200) {
            print("Attendance updated successfully");
            Navigator.pop(context);  // Close the scanner screen
          } else {
            print('Failed to update data. Status code: ${response.statusCode}');
            // Optionally, you can show an alert dialog to the user for failure
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Error"),
                content: Text("Failed to update attendance. Please try again."),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
