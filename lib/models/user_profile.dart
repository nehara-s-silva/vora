class UserProfile {
  String username;
  String email;
  String? photoUrl;
  int points;

  UserProfile({
    required this.username,
    required this.email,
    this.photoUrl,
    this.points = 0,
  });

  // Constructor to create UserProfile from JSON (Map) for Hive
  factory UserProfile.fromJson(Map<dynamic, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? 'User',
      email: json['email'] as String? ?? 'user@example.com',
      photoUrl: json['photoUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  // Method to convert UserProfile to JSON (Map) for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'points': points,
    };
  }
}
