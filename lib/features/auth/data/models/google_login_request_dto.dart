class GoogleLoginRequestDto {
  final String idToken;

  GoogleLoginRequestDto({required this.idToken});

  Map<String, dynamic> toJson() {
    return {'idToken': idToken};
  }
}
