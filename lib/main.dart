import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storage_system_comparison/objectbox_screen.dart';
import 'package:storage_system_comparison/todo.dart';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodoListScreen(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationSupportDirectory(); // More secure location
    final path = join(dir.path, 'todos_secure.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await instance.database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<Todo>> getAllTodos() async {
    final db = await instance.database;
    final maps = await db.query('todos', orderBy: 'id DESC');
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await instance.database;
    return await db.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(int id) async {
    final db = await instance.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Todo> todos = [];
  Todo? _editingTodo;

  @override
  void initState() {
    super.initState();
    _refreshTodoList();
  }

  Future<void> _refreshTodoList() async {
    final data = await dbHelper.getAllTodos();
    setState(() => todos = data);
  }

  Future<void> _addTodo(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Todo'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter todo title'),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ),
    );

    if (title?.isNotEmpty ?? false) {
      await dbHelper.insertTodo(Todo(title: title!));
      _refreshTodoList();
    }
  }

  Future<void> _editTodo(BuildContext context, Todo todo) async {
    setState(() => _editingTodo = todo);

    final title = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Todo'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter todo title'),
              controller: TextEditingController(text: todo.title),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ),
    );

    if (title?.isNotEmpty ?? false) {
      await dbHelper.updateTodo(todo.copyWith(title: title!));
      _refreshTodoList();
    }

    setState(() => _editingTodo = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQFlite Demo')),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return ListTile(
            title: Text(todo.title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: todo.isDone,
                  onChanged: (value) async {
                    await dbHelper.updateTodo(todo.copyWith(isDone: value!));
                    _refreshTodoList();
                  },
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTodo(context, todo)),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await dbHelper.deleteTodo(todo.id!);
                    _refreshTodoList();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _addTodo(context), child: const Icon(Icons.add)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ObjectBoxScreen()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Sqflite'),
          BottomNavigationBarItem(icon: const Icon(Icons.square), label: 'ObjectBox'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    dbHelper.close();
    super.dispose();
  }
}

extension on Todo {
  Todo copyWith({int? id, String? title, bool? isDone}) {
    return Todo(id: id ?? this.id, title: title ?? this.title, isDone: isDone ?? this.isDone);
  }
}
