class User {
  final int userID;
  final String email;
  final String? phone;
  final String? fullName;
  final DateTime? createdAt;
  final bool isVerified;
  final Map<String, dynamic>? quota;

  User({
    required this.userID,
    required this.email,
    this.phone,
    this.fullName,
    this.createdAt,
    this.isVerified = false,
    this.quota,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? json['UserID'] ?? 0,
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['Phone'],
      fullName: json['fullName'] ?? json['FullName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isVerified: json['isVerified'] ?? json['IsVerified'] ?? false,
      quota: json['quota'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'createdAt': createdAt?.toIso8601String(),
      'isVerified': isVerified,
      'quota': quota,
    };
  }
}