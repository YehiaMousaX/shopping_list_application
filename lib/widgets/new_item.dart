import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_application/data/categories.dart';
import 'package:shopping_list_application/models/category.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_list_application/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories.values.first;
  var _isSending = false;

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSending = true;
      });

      final url = Uri.https(
          'shopping-list-app-63d07-default-rtdb.firebaseio.com',
          'shopping-list.json');

      try {
        final response = await http.post(url,
            headers: {'Content-type': 'application/json'},
            body: json.encode({
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'category': _selectedCategory.title
            }));
        final Map<String, dynamic> resData = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(GroceryItem(
            id: resData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory));

        if (response.statusCode == 200) {
          print('Item added successfully: ${response.body}');
        } else {
          print('Failed to add item: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      } catch (error) {
        print('Error occurred: $error');
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1) {
                      return 'must be at least 2 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text('Quantity'),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: '1',
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! < 1) {
                            return 'must be a valid postive number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredQuantity = int.parse(value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField(
                          value: categories.values.first,
                          items: [
                            for (final category in categories.entries)
                              DropdownMenuItem(
                                  value: category.value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        color: category.value.color,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(category.value.title)
                                    ],
                                  ))
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value as Category;
                            });
                          }),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: _isSending
                            ? null
                            : () {
                                _formKey.currentState!.reset();
                              },
                        child: const Text("Reset")),
                    ElevatedButton(
                        onPressed: _isSending ? null : _addItem,
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(),
                              )
                            : const Text("Add Item"))
                  ],
                )
              ],
            )),
      ),
    );
  }
}
