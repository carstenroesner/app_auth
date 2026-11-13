import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_profile.dart';

/// Zentrale Verbindungsdaten. Der publishable Key ist öffentlich vorgesehen,
/// der Schutz der Daten hängt an Row Level Security in der Datenbank.
const String appAuthSupabaseUrl = 'https://vzcjmqvegtxgkbvtparo.supabase.co';
const String appAuthPublishableKey =
    'sb_publishable_j-qJDT5X-dkurcDcmwvG-w_m6BlrdeO';

/// Adresse des zentralen Konto-Portals. Alle Links in Mails (Bestätigung,
/// Passwort vergessen, E-Mail ändern) führen dorthin.
const String accountPortalUrl = 'https://carstenroesner.github.io/konto/';

/// Fehler mit einer für Nutzer lesbaren deutschen Meldung.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Verwaltet Anmeldung, Registrierung, Passwort und E-Mail-Adresse.
///
/// `AuthService.offline()` ist eine Variante ohne Server (Tests, oder wenn
/// die Initialisierung scheitert): Der Nutzer gilt dann als nicht angemeldet.
class AuthService extends ChangeNotifier {
  AuthService._(this._client);

  /// Variante ohne Server: alle Konto-Aktionen melden "nicht verfügbar".
  AuthService.offline() : _client = null;

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _sub;
  bool _recovery = false;
  UserProfile _profile = const UserProfile();
  String? _profileFor;

  /// Startet die Verbindung. Fehler führen zu `AuthService.offline()`.
  static Future<AuthService> init() async {
    try {
      await Supabase.initialize(
        url: appAuthSupabaseUrl,
        anonKey: appAuthPublishableKey,
      );
      final service = AuthService._(Supabase.instance.client);
      service._listen();
      service._syncProfile();
      return service;
    } catch (_) {
      return AuthService.offline();
    }
  }

  void _listen() {
    _sub = _client!.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) _recovery = true;
      _syncProfile();
      notifyListeners();
    }, onError: (_) {});
  }

  /// Name und Bild des angemeldeten Nutzers (leer, solange nichts geladen ist).
  UserProfile get profile => _profile;

  bool get available => _client != null;
  User? get user => _client?.auth.currentUser;
  bool get loggedIn => user != null;
  String? get email => user?.email;
  String? get userId => user?.id;

  /// Wahr, wenn der Nutzer über den Link "Passwort vergessen" gekommen ist und
  /// jetzt ein neues Passwort setzen muss.
  bool get recoveryPending => _recovery;

  SupabaseClient get client {
    final c = _client;
    if (c == null) throw const AuthFailure('Die Nutzerverwaltung ist gerade nicht verfügbar.');
    return c;
  }

  /// Adresse, auf die Links in Mails zurückführen: das zentrale Konto-Portal.
  String? get _redirect => kIsWeb ? accountPortalUrl : null;

  /// Lädt das Profil, sobald ein anderer Nutzer angemeldet ist, und leert es
  /// beim Abmelden.
  void _syncProfile() {
    final id = userId;
    if (id == _profileFor) return;
    _profileFor = id;
    _profile = const UserProfile();
    if (id != null) unawaited(_loadProfile(id));
  }

  Future<void> _loadProfile(String id) async {
    try {
      final row = await client
          .from('user_data')
          .select('value')
          .eq('app', 'account')
          .eq('key', 'profile')
          .maybeSingle();
      if (_profileFor != id) return;
      if (row != null) {
        _profile = UserProfile.fromJson(row['value']);
        notifyListeners();
      }
    } catch (_) {
      // Ohne Profil bleibt die Anzeige bei der E-Mail-Adresse.
    }
  }

  /// Speichert Name und Bild; sie gelten damit in allen Apps.
  Future<void> saveProfile(UserProfile profile) => _run(() async {
        final id = userId;
        if (id == null) throw const AuthFailure('Bitte zuerst anmelden.');
        await client.from('user_data').upsert(
          {
            'user_id': id,
            'app': 'account',
            'key': 'profile',
            'value': profile.toJson(),
          },
          onConflict: 'user_id,app,key',
        );
        _profile = UserProfile(
          firstName: profile.firstName.trim(),
          lastName: profile.lastName.trim(),
          avatar: profile.avatar,
        );
        notifyListeners();
      });

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(_translate(e));
    } catch (_) {
      throw const AuthFailure('Keine Verbindung zum Server. Bitte später erneut versuchen.');
    }
  }

  /// Legt ein Konto an. Danach muss der Link in der Bestätigungsmail
  /// angeklickt werden. Gibt `true` zurück, wenn eine Bestätigung aussteht.
  Future<bool> register(String email, String password) => _run(() async {
        final res = await client.auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: _redirect,
        );
        notifyListeners();
        return res.session == null;
      });

  Future<void> signIn(String email, String password) => _run(() async {
        await client.auth.signInWithPassword(email: email.trim(), password: password);
        notifyListeners();
      });

  Future<void> signOut() => _run(() async {
        await client.auth.signOut();
        _recovery = false;
        notifyListeners();
      });

  /// Schickt eine Mail mit Link zum Zurücksetzen des Passworts.
  Future<void> sendPasswordReset(String email) => _run(() async {
        await client.auth.resetPasswordForEmail(email.trim(), redirectTo: _redirect);
      });

  /// Setzt ein neues Passwort (angemeldet oder nach dem Reset-Link).
  Future<void> changePassword(String newPassword) => _run(() async {
        await client.auth.updateUser(UserAttributes(password: newPassword));
        _recovery = false;
        notifyListeners();
      });

  /// Ändert die E-Mail-Adresse. Die neue Adresse gilt erst nach Klick auf
  /// den Link in der Bestätigungsmail.
  Future<void> changeEmail(String newEmail) => _run(() async {
        await client.auth.updateUser(
          UserAttributes(email: newEmail.trim()),
          emailRedirectTo: _redirect,
        );
        notifyListeners();
      });

  static String _translate(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'E-Mail oder Passwort stimmt nicht.';
      case 'email_not_confirmed':
        return 'Die E-Mail-Adresse ist noch nicht bestätigt. Bitte den Link in der Mail anklicken.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Zu dieser E-Mail-Adresse gibt es schon ein Konto.';
      case 'weak_password':
        return 'Das Passwort ist zu schwach (mindestens 8 Zeichen, möglichst mit Zahlen).';
      case 'same_password':
        return 'Das neue Passwort muss sich vom alten unterscheiden.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Zu viele Anfragen. Bitte in einigen Minuten erneut versuchen.';
      case 'validation_failed':
      case 'email_address_invalid':
        return 'Die E-Mail-Adresse ist ungültig.';
      case 'signup_disabled':
        return 'Neue Anmeldungen sind derzeit nicht möglich.';
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login')) return 'E-Mail oder Passwort stimmt nicht.';
    if (msg.contains('rate limit')) return 'Zu viele Anfragen. Bitte in einigen Minuten erneut versuchen.';
    return 'Das hat nicht geklappt (${e.message}).';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
