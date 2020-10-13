import 'dart:async';
import 'package:jitsi/models/models.dart';
import 'package:jitsi/realtime/client.dart';
import 'package:jitsi/resourses/Styles.dart';
import 'package:jitsi/rest/client.dart';
import 'package:jitsi/ui/chat_room/CustomMessage.dart';
import 'package:jitsi/ui/chat_room/CustomMessageInput.dart';
import 'package:jitsi/ui/chat_room/MessageItem.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ChatRoom extends StatefulWidget {
  String roomId = "";
  Channel channel;
  Client client;
  ClientReal clientReal;

  ChatRoom(this.roomId, this.client, this.clientReal, {this.channel});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> with WidgetsBindingObserver {
  StreamController<bool> scrollStreamController = StreamController<bool>();
  AutoScrollController controller;

  Future<ChannelSubscription> messages;
  List<Message> newList = [];
  List<Message> oldList = [];
  ClientReal clientReal;
  bool top = false;

  @override
  void initState() {
    super.initState();
    newList.clear();

    controller = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical);
    WidgetsBinding.instance.addObserver(this);
    clientReal = widget.clientReal;
    // Future.delayed(const Duration(milliseconds: 500), () {
    widget.client.loadIMHistory(widget.roomId);
    //  });

    clientReal.roomMessages().listen((data) {
      if (data.doc != null && data.doc.values != null) {
        var valuesList = data.doc.values.toList();
        if (valuesList.length >= 2) {
          var list = valuesList[1];
          if (list.isNotEmpty && list.length >= 1) {
            var messageData = list[0];
            var mm = Message.fromJson(messageData);
            //  if (!widget.client.completer.isClosed) {
            newList.add(mm);
            widget.client.completer.sink.add(newList);
            if (!scrollStreamController.isClosed)
              scrollStreamController.sink.add(false);
            //  }
          }
        }
      }
    });
    controller.addListener(() {
      if (controller.offset <= controller.position.minScrollExtent) {
        if (!scrollStreamController.isClosed)
          scrollStreamController.sink.add(false);
//        setState(() {
        top = true;
//        });
//        if (!widget.client.lastPostion.isClosed)
//          widget.client.lastPostion.sink.add(newList.length);
        widget.client.loadIMHistory(widget.roomId, count: newList.length + 20);
      } else {
//        setState(() {
        top = false;
//        });
      }
    });
    scrollStreamController.stream.listen((event) {
      if (event) {
        //    if (newList.length <= 20) {
        print("last message " + newList[newList.length - 1].msg);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.animateTo(controller.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        });
        // }
      }
    });
    widget.client.lastPostion.stream.listen((event) {
      print("ScrollTooo=====>>> ${event}");
      print("ScrollTooo=====>>> ${event - 40}");
      _scrollToIndex(20);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);

    return Scaffold(
        appBar: AppBar(
            title: FutureBuilder<ChannelSubscription>(
                future: widget.client.getSubscriptionsOne(widget.roomId),
                builder: (_, response) {
                  return response.hasData && response.data != null
                      ? Text(response.data.name)
                      : Text("");
                })),
        body: Container(
            child: Stack(fit: StackFit.loose, children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Flexible(
                    fit: FlexFit.tight,
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: StreamBuilder<List<Message>>(
                            stream: widget.client.completer.stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                if (snapshot.data.length == 0) {
                                  return Center(
                                    child: Text(
                                      "Start messaging...",
                                      style: MESSAGE_TEXT_STYLE,
                                    ),
                                  );
                                } else {
                                  newList = snapshot.data;
                                  if (newList.length == 20) {
                                    scrollStreamController.sink.add(true);
                                  } else {
                                    if (top) {
                                      print("top $top");

                                      widget.client.lastPostion.sink
                                          .add(newList.length);
                                    }
                                    scrollStreamController.sink.add(false);
                                  }
                                  print(
                                      "messages List Length====>>>> ${newList.length}");

                                  return ListView.builder(
                                      controller: controller,
                                      itemCount: newList.length,
                                      itemBuilder: (_, int position) {
                                        final item = newList[position];
                                        return _wrapScrollTag(
                                            index: position,
                                            child: MessageItem(
                                              message: item.msg,
                                              time: item.timestamp,
//                                              userImageUrl: getUserImage(),
                                              messageAttachments:
                                                  getAttachmentType(
                                                      item.attachments),
                                              attachmentUrl:
                                                  "https://rocketdev.itgsolutions.com${getAttachmentUrl(item.attachments)}?rc_uid=${widget.client.getId()}&rc_token=${widget.client.getToken()}",
                                              messageType:
                                                  widget.client.getId() ==
                                                          item.user.id
                                                      ? MessageType.sent
                                                      : MessageType.received,
                                            ));
                                      });
                                }
                              } else
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                            }))),
                Divider(height: 0, color: Colors.black26),
                Container(
                  color: Colors.white,
                  height: 50,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CustomMessageInput(
                        sendMessage: sendMessage,
                        uploadFile: uploadFile,
                      )),
                ),
              ])
        ])));
  }

  void sendMessage(String text) async {
    await widget.clientReal.sendMessage(widget.roomId, text);
  }

  void uploadFile(String path, AttachmentType type) async {
    await widget.clientReal.Upload(
        file: File(path),
        roomId: widget.roomId,
        token: widget.client.getToken(),
        type: type,
        id: widget.client.getId());
  }

  void didUpdateWidget(ChatRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animateTo(controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() async {
    scrollStreamController.close();

    widget.client.completer.sink.add([]);

    super.dispose();
  }

  AttachmentType getAttachmentType(List<Attachment> attachments) {
    if (attachments != null) {
      if (attachments.length != 0 &&
          attachments[0].imageUrl != null &&
          attachments[0].imageUrl.isNotEmpty)
        return AttachmentType.image;
      else if (attachments.length != 0 &&
          attachments[0].audioUrl != null &&
          attachments[0].audioUrl.isNotEmpty)
        return AttachmentType.audio;
      else if (attachments.length != 0 &&
          attachments[0].videoUrl != null &&
          attachments[0].videoUrl.isNotEmpty)
        return AttachmentType.video;
      else
        return AttachmentType.text;
    } else
      return AttachmentType.text;
  }

  String getAttachmentUrl(List<Attachment> attachments) {
    if (attachments != null) {
      if (attachments.length != 0 &&
          attachments[0].imageUrl != null &&
          attachments[0].imageUrl.isNotEmpty)
        return attachments[0].imageUrl;
      else if (attachments.length != 0 &&
          attachments[0].audioUrl != null &&
          attachments[0].audioUrl.isNotEmpty)
        return attachments[0].audioUrl;
      else if (attachments.length != 0 &&
          attachments[0].videoUrl != null &&
          attachments[0].videoUrl.isNotEmpty)
        return attachments[0].videoUrl;
      else
        return "";
    } else
      return "";
  }

  Future _scrollToIndex(int position) async {
//    controller.jumpTo(position * 1.0);
    await controller.scrollToIndex(position,
        preferPosition: AutoScrollPosition.begin);
    controller.highlight(position);
    print("ScrollTooo=====>>> ${position}");
  }

  Widget _wrapScrollTag({int index, Widget child}) => AutoScrollTag(
        key: ValueKey(index),
        controller: controller,
        index: index,
        child: child,
        highlightColor: Colors.black.withOpacity(0.1),
      );
}
