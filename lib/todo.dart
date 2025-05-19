import 'package:objectbox/objectbox.dart';

@Entity()
class Todo {
  @Id()
  int id;
  final String title;
  bool isDone;
  
  Todo({this.id = 0, required this.title, this.isDone = false});

  Todo copyWith({int? id, String? title, bool? isDone}) {
    return Todo(id: id ?? this.id, title: title ?? this.title, isDone: isDone ?? this.isDone);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'is_done': isDone ? 1 : 0};
  }

  static Todo fromMap(Map<String, dynamic> map) {
    return Todo(id: map['id'], title: map['title'], isDone: map['is_done'] == 1);
  }
}