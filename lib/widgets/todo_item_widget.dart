import 'dart:io';

import 'package:flutter/material.dart';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachments/queue.dart';
import 'package:powersync_flutter_demo/widgets/photo_capture.dart';

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

  late String photoPath;

  Future<String?> _getPhotoPath(photoId) async {
    if (photoId == null) {
      return null;
    }
    photoPath =
        await attachmentQueue.attachmentsService.getLocalUri('$photoId.jpg');

    return photoPath;
  }

  Future<void> deleteTodo(TodoItem todo) async {
    if (todo.photoId != null) {
      Attachment? attachment =
          await attachmentQueue.attachmentsService.getAttachment(todo.photoId!);
      if (attachment != null) {
        await attachmentQueue.attachmentsService.updateAttachment(
            attachment.copyWith(state: AttachmentState.queuedDelete.index));
      }
    }
    await todo.delete();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getPhotoPath(widget.todo.photoId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          Widget takePhotoButton = ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TakePhotoWidget(todoId: widget.todo.id),
                ),
              );
            },
            child: const Text('Take Photo'),
          );

          Widget getPhotoWidget() {
            if (AppConfig.supabaseStorageBucket.isEmpty) {
              return Container();
            }

            if (widget.todo.photoId == null) {
              return takePhotoButton;
            }

            if (snapshot.hasData) {
              return Image.file(
                File(snapshot.data),
                width: 50,
                height: 50,
              );
            }

            return takePhotoButton;
          }

          Widget photoWidget = getPhotoWidget();

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
                  photoWidget,
                ],
              ));
        });
  }
}
