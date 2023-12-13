import 'dart:io';

import 'package:flutter/material.dart';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachments/queue.dart';
import 'package:powersync_flutter_demo/widgets/photo_capture.dart';

import '../models/todo_item.dart';

class TodoItemWidget extends StatelessWidget {
  TodoItemWidget({
    required this.todo,
  }) : super(key: ObjectKey(todo.id));

  final TodoItem todo;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  late String photoPath;

  Future<String?> _getPhotoPath(photoId) async {
    if (photoId == null) {
      return null;
    }
    Attachment? attachment =
        await attachmentQueue.attachmentService.getRecord(photoId);
    photoPath = await attachmentQueue.attachmentService
        .getLocalUri(attachment!.filename);
    return photoPath;
  }

  Future<void> deleteTodo(TodoItem todo) async {
    if (todo.photoId != null) {
      Attachment? attachment =
          await attachmentQueue.attachmentService.getRecord(todo.photoId!);
      await attachmentQueue.syncingService.deleteAttachment(attachment!);
    }
    await todo.delete();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getPhotoPath(todo.photoId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          Widget photoWidget = AppConfig.supabaseStorageBucket.isNotEmpty
              ? todo.photoId != null
                  ? snapshot.hasData
                      ? Image.file(
                          File(snapshot.data),
                          width: 50,
                          height: 50,
                        )
                      : TakePhotoWidget(todoId: todo.id)
                  : TakePhotoWidget(todoId: todo.id)
              : Container();

          return ListTile(
              onTap: todo.toggle,
              leading: Checkbox(
                value: todo.completed,
                onChanged: (_) {
                  todo.toggle();
                },
              ),
              title: Row(
                children: <Widget>[
                  Expanded(
                      child: Text(todo.description,
                          style: _getTextStyle(todo.completed))),
                  IconButton(
                    iconSize: 30,
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    alignment: Alignment.centerRight,
                    onPressed: () async => await deleteTodo(todo),
                    tooltip: 'Delete Item',
                  ),
                  photoWidget,
                ],
              ));
        });
  }
}
