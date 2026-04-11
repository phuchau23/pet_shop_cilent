class ProfileResponseDto {
  final int userId;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String userRole; // "Customer" | "Admin"
  final String accountStatus; // "Active" | "Inactive" | "Banned"
  final String? lastLogin;
  final String createdAt;
  final String updatedAt;

  ProfileResponseDto({
    required this.userId,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.userRole,
    required this.accountStatus,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return ProfileResponseDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0, // Handle null case
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      userRole: json['userRole'] as String? ?? 'Customer',
      accountStatus: json['accountStatus'] as String? ?? 'Active',
      lastLogin: json['lastLogin'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
