class Visit {
  final int id;
  final int devoteeId;
  final int itemId;
  final DateTime visitDate;
  final String? itemName;

  Visit({
    required this.id,
    required this.devoteeId,
    required this.itemId,
    required this.visitDate,
    this.itemName,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      devoteeId: json['devotee_id'],
      itemId: json['item_id'],
      visitDate: DateTime.parse(json['visit_date']),
      itemName: json['item'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'devotee_id': devoteeId,
      'item_id': itemId,
      'visit_date': visitDate.toIso8601String(),
      'item': itemName,
    };
  }
}