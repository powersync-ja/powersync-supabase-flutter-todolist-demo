import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart' as powersync;
import 'package:powersync_flutter_demo/attachments/camera_helpers.dart';
import 'package:powersync_flutter_demo/attachments/queue.dart';
import 'package:powersync_flutter_demo/models/todo_item.dart';
import 'package:powersync_flutter_demo/powersync.dart';

class TakePhotoWidget extends StatefulWidget {
  final String todoId;

  const TakePhotoWidget({super.key, required this.todoId});

  @override
  State<StatefulWidget> createState() {
    return _TakePhotoWidgetState();
  }
}

class _TakePhotoWidgetState extends State<TakePhotoWidget> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedPhoto;

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      camera!,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  // Dispose of the camera controller when the widget is disposed
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      // Ensure the camera is initialized before taking a photo
      await _initializeControllerFuture;

      final XFile photo = await _cameraController.takePicture();
      String storageDirectory =
          await attachmentQueue.attachmentService.getStorageDirectory();
      File newPhoto =
          File(photo.path).copySync('$storageDirectory/${photo.name}');

      setState(() {
        _capturedPhoto = photo;
      });

      int photoSize = await photo.length();
      String photoId = powersync.uuid.v4();
      TodoItem.addPhoto(photoId, widget.todoId);
      Uint8List photoAsBytes = newPhoto.readAsBytesSync();
      String photoAsBase64 = base64Encode(photoAsBytes);
      attachmentQueue.savePhoto(photoId, photo.name, photoSize, photoAsBase64);
    } catch (e) {
      log.info('Error taking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            height: 200, // Set a fixed height to avoid unbounded constraints
            width: 200,
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return _capturedPhoto != null
                      ? Image.file(
                          File(_capturedPhoto!.path),
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                      : CameraPreview(_cameraController);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            )),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _takePhoto,
          child: const Text('Take Photo'),
        ),
      ],
    );
  }
}
