class Visit {
  final int id;
  final int devoteeId;
  final int itemId;
  final DateTime visitDate;
  
  // Associated data
  final String? devoteeName;
  final String? devoteeRealId;
  final String? itemName;

  Visit({
    required this.id,
    required this.devoteeId,
    required this.itemId,
    required this.visitDate,
    this.devoteeName,
    this.devoteeRealId,
    this.itemName,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      devoteeId: json['devotee_id'],
      itemId: json['item_id'],
      visitDate: json['visit_date'] != null 
          ? DateTime.parse(json['visit_date']) 
          : DateTime.now(),
      devoteeName: json['devotee_name'],
      devoteeRealId: json['devotee_real_id'],
      itemName: json['item_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'devotee_id': devoteeId,
      'item_id': itemId,
      'visit_date': visitDate.toIso8601String(),
      'devotee_name': devoteeName,
      'devotee_real_id': devoteeRealId,
      'item_name': itemName,
    };
  }
}