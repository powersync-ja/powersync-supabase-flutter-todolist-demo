import 'package:flutter/material.dart';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachments/photo_widget.dart';
import 'package:powersync_flutter_demo/attachments/queue.dart';

import '../models/todo_item.dart';

class TodoItemWidget extends StatefulWidget {
  final TodoItem todo;

  TodoItemWidget({
    required this.todo,
  }) : super(key: ObjectKey(todo.id));

  @override
  State<StatefulWidget> createState() {
    return _TodoItemWidgetState();
  }
}

class _TodoItemWidgetState extends State<TodoItemWidget> {
  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  Future<void> deleteTodo(TodoItem todo) async {
    if (todo.photoId != null) {
      attachmentQueue.attachmentsService.saveAttachment(Attachment(
          id: todo.photoId!,
          filename: '${todo.photoId}.jpg',
          state: AttachmentState.queuedDelete.index));
    }
    await todo.delete();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: widget.todo.toggle,
        leading: Checkbox(
          value: widget.todo.completed,
          onChanged: (_) {
            widget.todo.toggle();
          },
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                child: Text(widget.todo.description,
                    style: _getTextStyle(widget.todo.completed))),
            IconButton(
              iconSize: 30,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              alignment: Alignment.centerRight,
              onPressed: () async => await deleteTodo(widget.todo),
              tooltip: 'Delete Item',
            ),
            AppConfig.supabaseStorageBucket.isEmpty
                ? Container()
                : PhotoWidget(todo: widget.todo),
          ],
        ));
  }
}
