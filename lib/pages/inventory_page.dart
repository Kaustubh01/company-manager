import 'dart:convert';
import 'package:attendance/comon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  // Add product method
  Future<void> addProduct(String itemName, int quantity, int price, String supplier) async {
    String? businessId = await _storage.read(key: 'business-id');
    if (businessId == null) {
      print("Business ID not found");
      return;
    }
    
    final url = Uri.parse('$baseurl/inventory/add-product');
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item_name': itemName,
          'quantity': quantity,
          'price': price,
          'supplier': supplier,
          'business_id': int.parse(businessId),
        }));
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product added successfully")),
      );
      _getInventoryItems();
    } else {
      print("Failed to add product");
    }
  }

  // Fetch inventory items from the API
  Future<void> _getInventoryItems() async {
    String? businessId = await _storage.read(key: 'business-id');
    if (businessId == null) {
      print("Business ID not found");
      return;
    }

    final url = Uri.parse('$baseurl/inventory/$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          items = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          isLoading = false;
        });
      } else {
        print("Error fetching items data");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching items data: $e");
      setState(() => isLoading = false);
    }
  }

  // Show the dialog to add a new product
  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: supplierController,
              decoration: InputDecoration(labelText: "Supplier"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              addProduct(
                nameController.text,
                int.tryParse(quantityController.text) ?? 0,
                int.tryParse(priceController.text) ?? 0,
                supplierController.text,
              );
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getInventoryItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text("Inventory is empty", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['item_name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text('Quantity: ${item['quantity']}'),
                                SizedBox(height: 5),
                                Text('Price: \$${item['price']}'),
                                SizedBox(height: 5),
                                Text('Supplier: ${item['supplier']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
