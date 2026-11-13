import 'dart:convert';
import 'dart:typed_data';

/// Name und Profilbild eines Nutzers. Gespeichert in `user_data`
/// (App `account`, Schlüssel `profile`), gilt damit in allen Apps.
class UserProfile {
  const UserProfile({this.firstName = '', this.lastName = '', this.avatar});

  final String firstName;
  final String lastName;

  /// Das Bild (JPEG oder PNG), bewusst klein gehalten.
  final Uint8List? avatar;

  bool get hasName => firstName.trim().isNotEmpty || lastName.trim().isNotEmpty;

  /// Vor- und Nachname, soweit vorhanden.
  String get fullName => [firstName.trim(), lastName.trim()]
      .where((s) => s.isNotEmpty)
      .join(' ');

  /// Initialen aus Vor- und Nachname, sonst leer.
  String get initials {
    String first(String s) {
      final t = s.trim();
      return t.isEmpty ? '' : String.fromCharCode(t.runes.first).toUpperCase();
    }

    return first(firstName) + first(lastName);
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    Uint8List? avatar,
    bool removeAvatar = false,
  }) =>
      UserProfile(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        avatar: removeAvatar ? null : (avatar ?? this.avatar),
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        if (avatar != null) 'avatar': base64Encode(avatar!),
      };

  factory UserProfile.fromJson(Object? json) {
    if (json is! Map) return const UserProfile();
    Uint8List? avatar;
    final raw = json['avatar'];
    if (raw is String && raw.isNotEmpty) {
      try {
        avatar = base64Decode(raw);
      } on FormatException {
        avatar = null;
      }
    }
    return UserProfile(
      firstName: json['firstName'] is String ? json['firstName'] as String : '',
      lastName: json['lastName'] is String ? json['lastName'] as String : '',
      avatar: avatar,
    );
  }
}

/// Was im Avatar steht: Initialen des Namens, sonst der Anfangsbuchstabe der
/// E-Mail-Adresse, sonst ein Fragezeichen.
String avatarLetters(UserProfile profile, String? email) {
  final initials = profile.initials;
  if (initials.isNotEmpty) return initials;
  final mail = (email ?? '').trim();
  if (mail.isEmpty) return '?';
  return String.fromCharCode(mail.runes.first).toUpperCase();
}
