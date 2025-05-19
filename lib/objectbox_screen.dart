import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_system_comparison/objectbox.g.dart';
import 'package:storage_system_comparison/todo.dart';

/// Screen demonstrating ObjectBox persistence implementation
/// 
/// Features:
/// - Create/store Todo items
/// - Delete items
/// - Automatic state persistence
/// - Reactive UI updates
class ObjectBoxScreen extends StatefulWidget {
  const ObjectBoxScreen({super.key});

  @override
  State<ObjectBoxScreen> createState() => _ObjectBoxScreenState();
}

/// State class managing ObjectBox operations and UI interactions
class _ObjectBoxScreenState extends State<ObjectBoxScreen> {
  /// ObjectBox storage reference for Todo entities
  late final Box<Todo> box;
  
  /// Controller for text input field
  final _controller = TextEditingController();
  
  /// Local cache of Todo items for UI display
  List<Todo> _items = [];

  /// Initialize ObjectBox store when widget is created
  @override
  void initState() {
    super.initState();
    _openStore(); // Start database initialization
  }

  /// Initialize ObjectBox store and database connection
  Future<void> _openStore() async {
    // Get platform-specific documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    
    // Open ObjectBox store with default configuration
    final store = await openStore(directory: docsDir.path);
    
    // Update state with Todo box reference
    setState(() => box = store.box<Todo>());
    
    // Load initial data
    _refreshItems();
  }

  /// Refresh UI with latest items from database
  void _refreshItems() {
    // Get all items from ObjectBox
    final all = box.getAll();
    
    // Reverse order to show newest first
    setState(() => _items = all.reversed.toList());
  }

  /// Add new Todo item to database
  void _addItem(String name) {
    // Create new Todo object (id is automatically assigned)
    final item = Todo(title: name);
    
    // Insert into ObjectBox (put() handles insert/update)
    box.put(item);
    
    // Clear input field
    _controller.clear();
    
    // Update UI with new data
    _refreshItems();
  }

  /// Delete item from database by ID
  void _deleteItem(int id) {
    // Remove item using ObjectBox ID
    box.remove(id);
    
    // Refresh UI state
    _refreshItems();
  }

  /// Build main UI layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ObjectBox PoC'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Row
            Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'New item',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _addItem(value.trim()),
                  ),
                ),
                
                // Add button
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) _addItem(text);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Todo list
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteItem(item.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}