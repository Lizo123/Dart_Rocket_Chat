import 'dart:async';
import 'dart:io';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jitsi/resourses/AppColors.dart';
import 'package:jitsi/resourses/Images.dart';
import 'package:jitsi/ui/camera_screen/TakeAPicutre.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:rxdart/rxdart.dart';
import 'CustomIconButton.dart';
import 'CustomMessage.dart';
import 'package:file/local.dart';

class CustomMessageInput extends StatefulWidget {
  Function sendMessage, uploadFile, uploadAudio;
  double iconSize;
  Color iconColor;
  bool addVideoAttachments, addImageAttachments, takePic;

  CustomMessageInput(
      {@required this.sendMessage,
      this.uploadFile,
      this.uploadAudio,
      this.addImageAttachments,
      this.addVideoAttachments,
      this.takePic,
      this.iconSize,
      this.iconColor});

  @override
  State<StatefulWidget> createState() {
    return CustomMessageInputState();
  }
}

class CustomMessageInputState extends State<CustomMessageInput> {
  String hintText = 'Type a message...';
  TextEditingController _text = new TextEditingController();
  Recording _recording = new Recording();
  LocalFileSystem localFileSystem;
  BehaviorSubject<bool> streamControllerForRecording = BehaviorSubject<bool>();

  @override
  void initState() {
    localFileSystem = localFileSystem ?? LocalFileSystem();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Visibility(
            visible: widget.takePic ?? true,
            child: CustomChatIconButton(
              iconSize: widget.iconSize ?? 35,
              iconAsset: CAMERA_MESSAGE,
              iconColor: widget.iconColor ?? BLUE_WHITE,
              permission: [Permission.camera],
              onPressed: () async {
                var firstCamera = await getCamera();
                String imagePath = await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return TakeAPicture(
                    camera: firstCamera,
                  );
                }));
                widget.uploadFile(imagePath, AttachmentType.image);
              },
            ),
          ),
          Visibility(
            visible: (widget.addVideoAttachments ?? true) ||
                (widget.addImageAttachments ?? true),
            child: CustomChatIconButton(
              iconSize: widget.iconSize ?? 35,
              iconAsset: ATTACHMENT_MESSAGE,
              iconColor: widget.iconColor ?? BLUE_WHITE,
              onPressed: () {
                showAttachmentBottomSheet(context);
              },
            ),
          ),
          _getTextField(),
          CustomChatIconButton(
            iconSize: widget.iconSize ?? 35,
            iconColor: BLUE_WHITE,
            icon: Icon(
              Icons.send,
              color: widget.iconColor ?? BLUE_WHITE,
            ),
            onPressed: () {
              if (_text.text.isNotEmpty) {
                widget.sendMessage(_text.text);
                _text.text = "";
              }
            },
          ),
          StreamBuilder<bool>(
            stream: streamControllerForRecording.stream,
            initialData: false,
            builder: (context, snap) {
              return Visibility(
                visible: !snap.data,
                child: CustomChatIconButton(
                  iconSize: widget.iconSize ?? 35,
                  iconAsset: MIC_MESSAGE,
                  iconColor: widget.iconColor ?? BLUE_WHITE,
                  permission: [Permission.storage, Permission.microphone],
                  onPressed: () {
                    start();
                  },
                ),
              );
            },
          ),
          StreamBuilder<bool>(
              stream: streamControllerForRecording.stream,
              initialData: false,
              builder: (context, snap) {
                return Visibility(
                  visible: snap.data,
                  child: CustomChatIconButton(
                    iconSize: widget.iconSize ?? 35,
                    icon: Icon(
                      Icons.pause,
                      color: widget.iconColor ?? BLUE_WHITE,
                    ),
                    onPressed: () {
                      getFileAndUpload();
                    },
                  ),
                );
              })
        ],
      ),
    );
  }

  getFileAndUpload() async {
    String file = await stop();
    widget.uploadFile(file, AttachmentType.audio);
  }

  Widget _getTextField() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xfff9f9f9),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: TextField(
          controller: _text,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            hintText: hintText,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Future<CameraDescription> getCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();
    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    return firstCamera;
  }

  showAttachmentBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                Visibility(
                  visible: widget.addImageAttachments ?? true,
                  child: ListTile(
                      leading: Icon(Icons.image),
                      title: Text('Image'),
                      onTap: () =>
                          showFilePicker(FileType.image, AttachmentType.image)),
                ),
                Visibility(
                  visible: widget.addVideoAttachments ?? true,
                  child: ListTile(
                      leading: Icon(Icons.videocam),
                      title: Text('Video'),
                      onTap: () =>
                          showFilePicker(FileType.video, AttachmentType.video)),
                ),
                /* ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('File'),
                  onTap: () =>
                      showFilePicker(FileType.any, AttachmentType.file),
                ),*/
              ],
            ),
          );
        });
  }

  showFilePicker(FileType fileType, AttachmentType type) async {
    File file = await FilePicker.getFile(type: fileType);
    print("file path=====>>>> ${file.path}");
    Navigator.pop(context);
    widget.uploadFile(file.path, type);
  }

  start() async {
    try {
      if (await AudioRecorder.hasPermissions) {
        await AudioRecorder.start();
        bool isRecording = await AudioRecorder.isRecording;
        if (!streamControllerForRecording.isClosed)
          streamControllerForRecording.sink.add(isRecording);
        _recording = new Recording(duration: new Duration(), path: "");
      } else {
        print("doesn't have permission");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> stop() async {
    var recording = await AudioRecorder.stop();
    print("Stop recording: ${recording.path}");
    bool isRecording = await AudioRecorder.isRecording;
    File file = localFileSystem.file(recording.path);
    print("  File length: ${await file.length()}");
    if (!streamControllerForRecording.isClosed)
      streamControllerForRecording.sink.add(isRecording);
    _recording = recording;
    return file.path;
  }

  @override
  void dispose() {
    streamControllerForRecording.close();
    super.dispose();
  }
}
