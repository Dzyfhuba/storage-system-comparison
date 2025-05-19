import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:storage_system_comparison/objectbox_screen.dart';
import 'package:storage_system_comparison/todo.dart';

/// Main application entry point
void main() => runApp(const TodoApp());

/// Root application widget configuring material design and navigation
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

/// SQLite database helper using singleton pattern
/// Manages database connection and CRUD operations
class DatabaseHelper {
  /// Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  /// Database reference cache
  static Database? _database;

  /// Private constructor for singleton pattern
  DatabaseHelper._privateConstructor();

  /// Database getter with lazy initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes database connection and creates schema if needed
  Future<Database> _initDatabase() async {
    // Use application support directory for better security
    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, 'todos_secure.db');
    
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create todos table schema
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

  /// Inserts new Todo into database
  /// Returns inserted row ID
  Future<int> insertTodo(Todo todo) async {
    final db = await instance.database;
    return await db.insert('todos', todo.toMap());
  }

  /// Retrieves all todos sorted by latest first
  Future<List<Todo>> getAllTodos() async {
    final db = await instance.database;
    final maps = await db.query('todos', orderBy: 'id DESC');
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  /// Updates existing Todo by ID
  /// Returns number of affected rows
  Future<int> updateTodo(Todo todo) async {
    final db = await instance.database;
    return await db.update(
      'todos', 
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// Deletes Todo by ID
  /// Returns number of affected rows
  Future<int> deleteTodo(int id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Closes database connection
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

/// Main screen displaying Todo list and handling user interactions
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

/// State management for Todo list screen
class _TodoListScreenState extends State<TodoListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Todo> todos = [];
  Todo? _editingTodo;  // Currently edited Todo item

  @override
  void initState() {
    super.initState();
    _refreshTodoList();  // Load initial data
  }

  /// Refresh UI with latest data from database
  Future<void> _refreshTodoList() async {
    final data = await dbHelper.getAllTodos();
    setState(() => todos = data);
  }

  /// Show dialog for adding new Todo
  Future<void> _addTodo(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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

  /// Show dialog for editing existing Todo
  Future<void> _editTodo(BuildContext context, Todo todo) async {
    setState(() => _editingTodo = todo);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: todo.title),
          decoration: const InputDecoration(hintText: 'Enter todo title'),
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

  /// Build main UI layout
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
                // Completion checkbox
                Checkbox(
                  value: todo.isDone,
                  onChanged: (value) async {
                    await dbHelper.updateTodo(todo.copyWith(isDone: value!));
                    _refreshTodoList();
                  },
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTodo(context, todo),
                ),
                // Delete button
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTodo(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ObjectBoxScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Sqflite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.square),
            label: 'ObjectBox',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    dbHelper.close();  // Clean up database connection
    super.dispose();
  }
}
