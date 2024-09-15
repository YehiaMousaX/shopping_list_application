import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_application/data/categories.dart';
import 'package:shopping_list_application/models/grocery_item.dart';
import 'package:shopping_list_application/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? error;

  void _loadItems() async {
    final url = Uri.https('shopping-list-app-63d07-default-rtdb.firebaseio.com',
        'shopping-list.json');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          error = 'Failed to fetch data';
        });
        return;
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Something went wrong: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem()));

    // _loadItems();

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    //http delete request
    final url = Uri.https('shopping-list-app-63d07-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      //to-do show error snackbar

      setState(() {
        error = 'Failed to delete item';
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'No items yet! Add some!',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
                onDismissed: (direction) {
                  _removeItem(_groceryItems[index]);
                },
                key: ValueKey(_groceryItems[index].id),
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    width: 25,
                    height: 25,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
              ));
    }

    if (error != null) {
      content = Center(
        child: Text(
          error!,
          style: const TextStyle(
              color: Colors.red, fontSize: 25, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF323A3C),
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
