import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_cart/data/categories.dart';
// import 'package:shopping_cart/models/category.dart';

import 'package:shopping_cart/widgets/new_item.dart';
import 'package:lottie/lottie.dart';
import '../models/grocery_item.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    //fetch data here
    final url = Uri.https(
        'flutter-prep-aaa7f-default-rtdb.firebaseio.com', 'shopping-list.json');

    try {
      final response = await http.get(url);
      // checking for any error
      if (response.statusCode >= 400) {
        setState(() {
          print(response.statusCode);
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      // if backend sends null then this case is executed
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      //check for the internet connection
      //this is one way which is provided by flutter to throw error by using 'throw' keyword
      //throw Exception('An error occurred while');
      //try catch is used to handle this kind of error

      //listed data is in the form of map and thats why we use map here Map<key in the form of string : values in the form of Map >
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
              id: item.key,
              name: item.value['name'],
              quantity: item.value['quantity'],
              category: category),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    //getting index of the item so that when we UNDO that it will be displayed at that place only.
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    //deleting the item in the firebase
    final url = Uri.https('flutter-prep-aaa7f-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      //UNDO logic
      setState(() {
        const Text('ERROR while deleting the item');
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation widget
          Lottie.asset(
            'assets/images/addData.json',
            width: 300,
            height: 300,
            fit: BoxFit.cover,
            repeat: false,
          ),
          const SizedBox(height: 20),
          // Animated text widget with typing effect
          TyperAnimatedTextKit(
            text: ['No items added yet...'],
            textStyle: const TextStyle(
              fontSize: 26.0,
            ),
            textAlign: TextAlign.center,
            isRepeatingAnimation: false,
            speed: const Duration(milliseconds: 100),
          ),
        ],
      ),
    );

    // this content will be displayed when content is loading

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          background: Container(
            color: Colors.red, // Set background color to red
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
