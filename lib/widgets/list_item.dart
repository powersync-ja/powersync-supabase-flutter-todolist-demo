import 'package:flutter/material.dart';

import './todo_list_page.dart';
import '../models/todo_list.dart';

class ListItemWidget extends StatelessWidget {
  ListItemWidget({
    required this.list,
  }) : super(key: ObjectKey(list));

  final TodoList list;

  Future<void> delete() async {
    // Server will take care of deleting related todos
    await list.delete();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          var navigator = Navigator.of(context);

          navigator.push(MaterialPageRoute(
              builder: (context) => TodoListPage(list: list)));
        },
        title: Row(
          children: <Widget>[
            Expanded(child: Text(list.name)),
            IconButton(
              iconSize: 30,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              alignment: Alignment.centerRight,
              onPressed: delete,
            )
          ],
        ));
  }
}
