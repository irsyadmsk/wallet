import 'package:hive/hive.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 8)
class TagModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int? colorValue;

  @HiveField(3)
  int orderSeq;

  @HiveField(4)
  bool isArchived;

  @HiveField(5)
  String? externalId;

  TagModel({
    required this.id,
    required this.name,
    this.colorValue,
    this.orderSeq = 0,
    this.isArchived = false,
    this.externalId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'orderSeq': orderSeq,
        'isArchived': isArchived,
        'externalId': externalId,
      };

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel(
        id: json['id'] as String,
        name: json['name']?.toString() ?? '',
        colorValue: json['colorValue'] == null ? null : int.tryParse(json['colorValue'].toString()),
        orderSeq: int.tryParse(json['orderSeq'].toString()) ?? 0,
        isArchived: json['isArchived'] as bool? ?? false,
        externalId: json['externalId'] as String?,
      );
}
