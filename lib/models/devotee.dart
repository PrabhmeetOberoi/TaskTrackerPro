class Devotee {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;

  Devotee({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Devotee.fromJson(Map<String, dynamic> json) {
    return Devotee(
      id: json['devotee_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devotee_id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}