import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jitsi/resourses/AppColors.dart';
import 'package:jitsi/resourses/Dimens.dart';
import 'package:jitsi/resourses/Styles.dart';

enum MessageType { sent, received }
enum AttachmentType { image, video, file, audio }

class CustomMessageText extends StatelessWidget {
  double minWidth, maxWidth;
  String message;
  DateTime time;
  MessageType messageType;

  CustomMessageText(
      {this.messageType,
      @required this.message,
      @required this.time,
      this.maxWidth,
      this.minWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: DIMEN_2,
        horizontal: DIMEN_8,
      ),
      margin: EdgeInsets.symmetric(
        vertical: DIMEN_4,
        horizontal: DIMEN_12,
      ),
      constraints: BoxConstraints(
          minWidth: minWidth ?? DIMEN_100, maxWidth: maxWidth ?? DIMEN_200),
      decoration: BoxDecoration(
        color: messageBgColor(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topLeftRadius()),
          topRight: Radius.circular(topRightRadius()),
          bottomLeft: Radius.circular(DIMEN_8),
          bottomRight: Radius.circular(DIMEN_8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: messageAlignment(),
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: DIMEN_4,
              horizontal: DIMEN_4,
            ),
            child:
                Text(message ?? "Message here...", style: MESSAGE_TEXT_STYLE),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: DIMEN_2,
            ),
            child: messageTime(),
          ),
        ],
      ),
    );
  }

  Color messageBgColor(BuildContext context) {
    if (messageType == null || messageType == MessageType.sent) {
      return LIGHT_CYN_MESSAGE_BG_COLOR;
    } else {
      return Colors.grey.shade200;
    }
  }

  Text messageTime() {
    return Text(getTime(time) ?? "Time", style: TIME_STYLE);
  }

  double topLeftRadius() {
    if (messageType == null || messageType == MessageType.received) {
      return DIMEN_0;
    } else {
      return DIMEN_8;
    }
  }

  double topRightRadius() {
    if (messageType == null || messageType == MessageType.received) {
      return DIMEN_8;
    } else {
      return DIMEN_0;
    }
  }

  CrossAxisAlignment messageAlignment() {
    if (messageType == null || messageType == MessageType.received) {
      return CrossAxisAlignment.start;
    } else {
      return CrossAxisAlignment.end;
    }
  }

  String getTime(DateTime timestamp) {
    var format = new DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp);
    return format;
  }
}
