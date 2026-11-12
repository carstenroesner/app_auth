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
}
