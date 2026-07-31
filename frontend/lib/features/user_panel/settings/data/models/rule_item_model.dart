import '../../domain/entities/rule_item.dart';

class RuleItemModel extends RuleItem {
  const RuleItemModel({
    required super.id,
    required super.title,
    required super.description,
  });

  factory RuleItemModel.fromJson(Map<String, dynamic> json) {
    return RuleItemModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}
