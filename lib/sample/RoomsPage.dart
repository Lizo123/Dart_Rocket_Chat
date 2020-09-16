import 'package:flutter/material.dart';
import 'package:jitsi/models/models.dart';
import 'package:jitsi/realtime/client.dart';
import 'package:jitsi/rest/client.dart';
import 'package:jitsi/room_realtime_repo.dart';
import 'package:jitsi/ui/rooms_list/ChatRoomCircleAvatar.dart';
import 'package:jitsi/ui/rooms_list/ChatRoomItem.dart';

import 'chatRoom.dart';

class ChatRooms extends StatefulWidget {
  @override
  _ChatRoomsState createState() => _ChatRoomsState();
}

class _ChatRoomsState extends State<ChatRooms> {
  Client client;
  ClientReal clientReal;
  String roomId;
  List<ChannelSubscription> list = new List();

  @override
  void initState() {
    super.initState();
    client = new Client(
        Uri(scheme: "http", host: "rocketdev.itgsolutions.com"), false);

    UserCredentials userCredentials = new UserCredentials(
        id: "g5LLpo3ba2EPPekBF",
        token: "N4znKscFWouwYYi9EaDWh8M4axbcqJ8ZSDBx99175de");
    client.setCredentials(userCredentials);
  }

  @override
  Widget build(BuildContext context) {
    //  initializingclientReal();
    return Scaffold(
        body: FutureBuilder<List<ChannelSubscription>>(
            future: client.getSubscriptions(),
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (_, int position) {
                        final item = snapshot.data[position];
                        roomId = item != null ? item.roomId : "";
                        return item != null && !item.name.contains("call")
                            ? ChatRoomItem(
                                leading: ChatRoomCircleAvatar(
                                  imageUrl: "",
                                  status: item.user != null &&
                                          item.user.status == null
                                      ? ChatStatus.offline
                                      : item.user != null &&
                                              item.user.status != null &&
                                              item.user.status == "online"
                                          ? ChatStatus.online
                                          : ChatStatus.busy,
                                ),
                                channel: item,
                                onTapFunction: navigateToChat,
                              )
                            : Container();
                      })
                  : Center(
                      child: CircularProgressIndicator(),
                    );
            }));
  }

  initializingclientReal() async {}


//  navigateToChat(String id, Channel item) {
  navigateToChat(String id) async {
    clientReal =
        await RoomRealTimeRepo.startRoomChat(id, 'pa0707', 'Ab@123456');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatRoom(id, client, clientReal)),
    );
  }
}
