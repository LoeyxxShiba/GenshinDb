import 'package:flutter/widgets.dart';
import 'package:genshindb/domain/enums/enums.dart';
import 'package:genshindb/domain/models/entities/notifications/notification_base.dart';
import 'package:hive/hive.dart';

part 'notification_custom.g.dart';

@HiveType(typeId: 9)
class NotificationCustom extends HiveObject implements NotificationBase {
  @override
  @HiveField(0)
  final int type;

  @override
  @HiveField(1)
  String itemKey;

  @override
  @HiveField(2)
  final DateTime createdAt;

  @override
  @HiveField(3)
  final DateTime originalScheduledDate;

  @override
  @HiveField(4)
  DateTime completesAt;

  @override
  @HiveField(5)
  bool showNotification;

  @override
  @HiveField(6)
  String note;

  @override
  @HiveField(7)
  String title;

  @override
  @HiveField(8)
  String body;

  @HiveField(9)
  int notificationItemType;

  NotificationCustom({
    @required this.itemKey,
    @required this.createdAt,
    @required this.completesAt,
    this.note,
    @required this.showNotification,
    @required this.title,
    @required this.body,
    @required this.notificationItemType,
  })  : type = AppNotificationType.custom.index,
        originalScheduledDate = completesAt;
}