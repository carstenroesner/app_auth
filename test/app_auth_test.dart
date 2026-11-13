import 'dart:typed_data';

import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Offline-Variante: nicht angemeldet, Cloud-Speicher inaktiv', () async {
    final auth = AuthService.offline();
    expect(auth.available, isFalse);
    expect(auth.loggedIn, isFalse);
    final store = CloudStore(auth, appId: 'test');
    expect(store.active, isFalse);
    expect(await store.load('k'), isNull);
    expect(await store.save('k', '{}'), isNull);
    expect(() => auth.signIn('a@b.de', 'x'), throwsA(isA<AuthFailure>()));
  });

  testWidgets('Konto-Bildschirm ohne Server nennt lokalen Betrieb', (tester) async {
    final auth = AuthService.offline();
    await tester.pumpWidget(MaterialApp(home: AccountScreen(auth: auth, appName: 'Testapp')));
    expect(find.textContaining('arbeitet weiter lokal'), findsOneWidget);
  });

  testWidgets('App-Konto ohne Server nennt lokalen Betrieb', (tester) async {
    final auth = AuthService.offline();
    await tester.pumpWidget(MaterialApp(home: AppAccountScreen(auth: auth, appName: 'Testapp')));
    expect(find.textContaining('arbeitet weiter lokal'), findsOneWidget);
  });

  test('Rücksprung nur zu eigenen Apps', () {
    expect(isAllowedReturnUrl('https://carstenroesner.github.io/prompt_arena/'), isTrue);
    expect(isAllowedReturnUrl('https://evil.example.com/'), isFalse);
    expect(isAllowedReturnUrl('javascript:alert(1)'), isFalse);
    expect(isAllowedReturnUrl(null), isFalse);
  });

  group('Profil und Avatar', () {
    test('Initialen aus Vor- und Nachname', () {
      const p = UserProfile(firstName: 'carsten', lastName: 'Rösner');
      expect(p.initials, 'CR');
      expect(avatarLetters(p, 'info@example.de'), 'CR');
      expect(p.fullName, 'carsten Rösner');
    });

    test('Nur ein Name ergibt einen Buchstaben, ohne Namen zählt die Mail', () {
      expect(avatarLetters(const UserProfile(firstName: 'anna'), 'x@y.de'), 'A');
      expect(avatarLetters(const UserProfile(), 'info@example.de'), 'I');
      expect(avatarLetters(const UserProfile(), null), '?');
      expect(avatarLetters(const UserProfile(firstName: '  '), 'z@y.de'), 'Z');
    });

    test('Profil übersteht die Umwandlung in JSON', () {
      final p = UserProfile(
        firstName: ' Anna ',
        lastName: 'Beck',
        avatar: Uint8List.fromList([1, 2, 3]),
      );
      final back = UserProfile.fromJson(p.toJson());
      expect(back.firstName, 'Anna');
      expect(back.lastName, 'Beck');
      expect(back.avatar, [1, 2, 3]);
      expect(UserProfile.fromJson(null).hasName, isFalse);
      expect(UserProfile.fromJson({'avatar': '%%%'}).avatar, isNull);
    });

    testWidgets('Ohne Anmeldung zeigt der Avatar ein Schloss', (tester) async {
      final auth = AuthService.offline();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AccountAvatar(auth: auth))),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
