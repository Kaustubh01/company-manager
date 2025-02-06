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
          for (final barcode in barcodes) {
            print("Barcode found ${barcode.rawValue}");
          }
          if (image != null) {
            Map<String, dynamic> idMap =
                jsonDecode(barcodes.first.rawValue ?? '{}');
            print(idMap);
            DateTime lastRecorded =
                DateTime.parse(idMap["lastAttendanceRecorded"]).toUtc();
            DateTime now = DateTime.now().toUtc();
            String name = idMap["name"];
            if (lastRecorded.isBefore(now)) {
              String? businessId = await _storage.read(key: 'business-id');
              final url = Uri.parse('$baseurl/business/$businessId/employees/update-attendance');
              final response = await http.put(url,
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({"id": idMap["id"]}));
              if (response.statusCode == 200) {
                print("Attendance updated successfully");
                Navigator.pop(context);
              } else {
                print(
                    'Failed to update data. Status code: ${response.statusCode}');
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name already marked attendance today."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
