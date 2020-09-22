import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jitsi/resourses/AppColors.dart';
import 'package:jitsi/resourses/Images.dart';
import 'file:///D:/flutter%20chat/Dart_Rocket_Chat/lib/ui/camera_screen/TakeAPicutre.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'CustomIconButton.dart';
import 'CustomMessage.dart';

class CustomMessageInput extends StatefulWidget {
  Function sendMessage, uploadFile, startRecord, stopRecording, uploadAudio;
  double iconSize;
  Color iconColor;
  String roomId;
  String id;
  String token;
  bool isRecording;

  CustomMessageInput(
      {@required this.sendMessage,
      this.uploadFile,
      this.roomId,
      this.id,
      this.startRecord,
      this.stopRecording,
      this.isRecording,
      this.token,
      this.uploadAudio});

  @override
  State<StatefulWidget> createState() {
    return CustomMessageInputState();
  }
}

class CustomMessageInputState extends State<CustomMessageInput> {
  String hintText = 'Type a message...';
  TextEditingController _text = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Visibility(
            visible: true,
            child: CustomIconButton(
              iconSize: 35,
              iconAsset: CAMERA_MESSAGE,
              iconColor: BLUE_WHITE,
              permission: [Permission.camera],
              onPressed: () async {
                var firstCamera = await getCamera();
                String imagePath = await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return TakeAPicture(
                    camera: firstCamera,
                  );
                }));
                print("image path=====>> $imagePath");
                widget.uploadFile(imagePath, AttachmentType.image);
              },
            ),
          ),
          Visibility(
            visible: true,
            child: CustomIconButton(
              iconSize: 35,
              iconAsset: ATTACHMENT_MESSAGE,
              iconColor: BLUE_WHITE,
              onPressed: () {
                showAttachmentBottomSheet(context);
              },
            ),
          ),
          _getTextField(),
          CustomIconButton(
            iconSize: 35,
            iconColor: BLUE_WHITE,
            icon: Icon(
              Icons.send,
              color: BLUE_WHITE,
            ),
            onPressed: () {
              if (_text.text.isNotEmpty) {
                widget.sendMessage(_text.text);
                _text.text = "";
              }
            },
          ),
          Visibility(
            visible: !widget.isRecording,
            child: CustomIconButton(
              iconSize: 35,
              iconAsset: MIC_MESSAGE,
              iconColor: BLUE_WHITE,
              permission: [Permission.storage, Permission.microphone],
              onPressed: () {
                widget.startRecord();
              },
            ),
          ),
          Visibility(
            visible: widget.isRecording,
            child: CustomIconButton(
              iconSize: 35,
              icon: Icon(
                Icons.pause,
                color: BLUE_WHITE,
              ),
              onPressed: () {
                getFileAndUpload();
              },
            ),
          ),
        ],
      ),
    );
  }

  getFileAndUpload() async {
    String file = await widget.stopRecording();
    widget.uploadFile(file, AttachmentType.audio);
//    widget.uploadAudio(file);
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
                ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Image'),
                    onTap: () =>
                        showFilePicker(FileType.image, AttachmentType.image)),
                ListTile(
                    leading: Icon(Icons.videocam),
                    title: Text('Video'),
                    onTap: () =>
                        showFilePicker(FileType.video, AttachmentType.video)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('File'),
                  onTap: () =>
                      showFilePicker(FileType.any, AttachmentType.file),
                ),
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
}
