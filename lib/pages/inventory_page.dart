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

  @override
  void initState() {
    super.initState();
    _getInventoryItems();
  }

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

  Future<void> addProduct(String itemName, int quantity, int price, String supplier, String category) async {
    String? businessId = await _storage.read(key: 'business-id');
    if (businessId == null) {
      print("Business ID not found");
      return;
    }

    final url = Uri.parse('$baseurl/inventory/add-product');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'supplier': supplier,
        'category': category,
        'business_id': int.parse(businessId),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product added successfully")),
      );
      _getInventoryItems();
    } else {
      print("Failed to add product: ${response.body}");
    }
  }

  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Product"),
        content: SingleChildScrollView(
          child: Column(
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
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: "Category"),
              ),
            ],
          ),
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
                categoryController.text,
              );
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByCategory() {
    Map<String, List<Map<String, dynamic>>> categorizedItems = {};
    for (var item in items) {
      final category = item['category'] ?? 'Uncategorized';
      if (!categorizedItems.containsKey(category)) {
        categorizedItems[category] = [];
      }
      categorizedItems[category]!.add(item);
    }
    return categorizedItems;
  }

  @override
  Widget build(BuildContext context) {
    final categorizedItems = _groupItemsByCategory();

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
          : ListView(
        children: categorizedItems.entries.map((entry) {
          return ExpansionTile(
            title: Text(
              entry.key,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            children: entry.value.map((item) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item_name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Quantity: ${item['quantity']}'),
                        SizedBox(height: 4),
                        Text('Price: \$${item['price']}'),
                        SizedBox(height: 4),
                        Text('Supplier: ${item['supplier']}'),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
