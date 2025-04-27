import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;

  // Initialize secure storage
  final _storage = FlutterSecureStorage();

  // Fetch sales data from the API
  Future<void> _getSales() async {
    String? businessId = await _storage.read(key: 'business-id');
    if (businessId == null) {
      print("Business ID is not available in secure storage.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('$baseurl/sales/$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          salesData = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        print("Error fetching sales data: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching sales data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getSales();  // Fetch sales when the page loads
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date).toLocal();
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  DataRow buildDataRow(Map<String, dynamic> sale) {
    return DataRow(cells: [
      DataCell(Text(sale['sale_id'].toString())),
      DataCell(Text(sale['customerName'] ?? 'N/A')),
      DataCell(Text(sale['itemName'] ?? 'N/A')),
      DataCell(Text(sale['quantitySold'].toString())),
      DataCell(Text(formatDate(sale['saleDate']))),
      DataCell(Text(sale['totalPrice'].toString())),
    ]);
  }

  Future<void> _exportSalesDataToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Sales Data', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Sale ID', 'Customer Name', 'Item Name', 'Quantity Sold', 'Sale Date', 'Total Price'],
                data: salesData.map((sale) => [
                  sale['sale_id'].toString(),
                  sale['customerName'] ?? 'N/A',
                  sale['itemName'] ?? 'N/A',
                  sale['quantitySold'].toString(),
                  formatDate(sale['saleDate']),
                  sale['totalPrice'].toString(),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Preview, Print or Share the generated PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Data"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesData.isEmpty
          ? const Center(child: Text("No sales data available", style: TextStyle(fontSize: 18)))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Sale ID")),
            DataColumn(label: Text("Customer Name")),
            DataColumn(label: Text("Item Name")),
            DataColumn(label: Text("Quantity Sold")),
            DataColumn(label: Text("Sale Date")),
            DataColumn(label: Text("Total Price")),
          ],
          rows: salesData.map(buildDataRow).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportSalesDataToPDF,
        child: const Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }
}
