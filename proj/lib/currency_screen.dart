import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyScreen extends StatefulWidget {
  final Future<void> Function() onCurrencyAdded;

  const CurrencyScreen({super.key, required this.onCurrencyAdded});

  @override
  _CurrencyScreenState createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  List<String> currencies = []; // List for storing currency names

  @override
  void initState() {
    super.initState();
    fetchCurrencies(); // Fetch the currencies when the screen is loaded
  }

  // Fetch currencies from the API
  Future<void> fetchCurrencies() async {
    try {
      final response = await http.get(Uri.parse('https://alym.pythonanywhere.com/get_currenciesname/'));
      print(response.body); // Log the response body

      if (response.statusCode == 200) {
        setState(() {
          currencies = List<String>.from(jsonDecode(response.body)); // Convert JSON to a list of strings
        });
      } else {
        print('Failed to load currencies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Add a new currency
Future<void> addCurrency(String name, String code) async {
  try {
    final response = await http.post(
      Uri.parse('https://alym.pythonanywhere.com/add_currency/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'code': code}),
    );

    if (response.statusCode == 200) {
      await widget.onCurrencyAdded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении валюты: ${response.body}')),
      );
    }
  } catch (e) {
    print('Ошибка: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currencies'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Container(
          width: 280, // Smaller container width
          height: 400, // Smaller container height
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Displaying the list of currencies
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        currencies[index],
                        style: const TextStyle(fontSize: 16), // Smaller font size
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Button to add a new currency
              ElevatedButton(
                onPressed: () {
                  // Show a dialog to add a new currency
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      TextEditingController nameController = TextEditingController();
                      TextEditingController codeController = TextEditingController();

                      return AlertDialog(
                        title: const Text('Add New Currency'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Currency name input field
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Currency Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Currency code input field
                            TextField(
                              controller: codeController,
                              decoration: const InputDecoration(
                                labelText: 'Currency Code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          // Cancel button
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          // Add button
                          ElevatedButton(
                            onPressed: () {
                              addCurrency(nameController.text, codeController.text);
                              Navigator.of(context).pop(); // Close the dialog after adding
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(180, 40), // Smaller button size
                ),
                child: const Text(
                  'New Currency',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

