import 'package:objectbox/objectbox.dart';

/// Represents a Todo item persistent entity
/// 
/// Annotated with @Entity to mark this class for ObjectBox persistence
/// 
/// Example:
/// ```dart
/// final todo = Todo(title: 'Buy milk');
/// final doneTodo = Todo(title: 'Clean room', isDone: true);
/// ```
@Entity()
class Todo {
  /// ObjectBox entity ID (primary key)
  /// Annotated with @Id() to identify as primary key
  /// Defaults to 0 (indicates new entity not yet persisted)
  @Id()
  int id;

  /// Todo item title (immutable once created)
  /// Marked final to prevent modification after creation
  final String title;

  /// Completion status of the todo item
  /// Mutable to allow updates through toggle operations
  bool isDone;

  /// Main constructor for Todo items
  /// 
  /// Parameters:
  /// - [id] : Optional database ID (default 0 for new items)
  /// - [title] : Required task description
  /// - [isDone] : Completion status (default false)
  Todo({this.id = 0, required this.title, this.isDone = false});

  /// Creates a copy of this Todo with updated values
  /// 
  /// Parameters (all optional):
  /// - [id] : New ID if provided
  /// - [title] : New title if provided
  /// - [isDone] : New completion status if provided
  /// 
  /// Returns:
  /// A new Todo instance with updated values
  Todo copyWith({int? id, String? title, bool? isDone}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  /// Converts Todo to a Map<String, dynamic> for serialization
  /// 
  /// Note: Not required by ObjectBox, but useful for:
  /// - JSON serialization
  /// - Debugging
  /// - Compatibility with other storage systems
  /// 
  /// Returns:
  /// Map representation of the Todo item
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0, // Convert boolean to integer (SQL-like storage)
    };
  }

  /// Creates a Todo from a Map<String, dynamic>
  /// 
  /// Parameters:
  /// - [map] : Map containing Todo properties
  /// 
  /// Returns:
  /// New Todo instance with values from the map
  /// 
  /// Note: Handles conversion of integer back to boolean
  static Todo fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isDone: map['is_done'] == 1, // Convert integer back to boolean
    );
  }
}