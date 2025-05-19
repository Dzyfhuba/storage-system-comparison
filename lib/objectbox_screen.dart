import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_system_comparison/objectbox.g.dart';
import 'package:storage_system_comparison/todo.dart';

class ObjectBoxScreen extends StatefulWidget {
  const ObjectBoxScreen({super.key});

  @override
  State<ObjectBoxScreen> createState() => _ObjectBoxScreenState();
}

class _ObjectBoxScreenState extends State<ObjectBoxScreen> {
  late final Box<Todo> box;
  final _controller = TextEditingController();
  List<Todo> _items = [];

  @override
  void initState() {
    super.initState();
    _openStore();
  }

  Future<void> _openStore() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: docsDir.path);
    setState(() => box = store.box<Todo>());
    _refreshItems();
  }

  void _refreshItems() {
    final all = box.getAll();
    setState(() => _items = all.reversed.toList());
  }

  void _addItem(String name) {
    final item = Todo(title: name);
    box.put(item);
    _controller.clear();
    _refreshItems();
  }

  void _deleteItem(int id) {
    box.remove(id);
    _refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ObjectBox PoC')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'New item'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) _addItem(text);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.title),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
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

