import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jitsi/resourses/AppColors.dart';
import 'package:jitsi/resourses/Images.dart';

import 'package:jitsi/ui/chat_room/TakeAPicutre.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import '../../Singletoon.dart';

import 'CustomIconButton.dart';

class CustomMessageInput extends StatefulWidget {
  Function sendMessage;
  double iconSize;
  Color iconColor;
  String roomId;
  String id;
  String token;

  CustomMessageInput(
      {@required this.sendMessage, this.roomId, this.id, this.token});

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
              permission: Permission.camera,
              onPressed: () async {
                var firstCamera = await getCamera();
                String imagePath = await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return TakeAPicture(
                    camera: firstCamera,
                  );
                }));
                print("image path=====>> $imagePath");
              },
            ),
          ),
          Visibility(
            visible: true,
            child: CustomIconButton(
              iconSize: 35,
              iconAsset: ATTACHMENT_MESSAGE,
              iconColor: BLUE_WHITE,
//              permission: Permission.storage,
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
            visible: true,
            child: CustomIconButton(
              iconSize: 35,
              iconAsset: MIC_MESSAGE,
              iconColor: BLUE_WHITE,
//              permission: Permission.microphone,
            ),
          ),
        ],
      ),
    );
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
    final cameras = await availableCameras();
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
                    onTap: () => showFilePicker(FileType.image)),
                ListTile(
                    leading: Icon(Icons.videocam),
                    title: Text('Video'),
                    onTap: () => showFilePicker(FileType.video)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('File'),
                  onTap: () => showFilePicker(FileType.any),
                ),
              ],
            ),
          );
        });
  }

  showFilePicker(FileType fileType) async {
    File file = await FilePicker.getFile(type: fileType);
    print("file path=====>>>> ${file.path}");
    Navigator.pop(context);
//    GradientSnackBar.showMessage(context, 'Sending attachment..');
  }
}
