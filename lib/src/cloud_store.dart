import 'dart:convert';

import 'auth_service.dart';

/// Ein gespeicherter Wert mit Zeitpunkt der letzten Änderung auf dem Server.
class CloudEntry {
  const CloudEntry(this.json, this.updatedAt);
  final String json;
  final DateTime updatedAt;
}

/// Speichert JSON-Werte pro Nutzer, App und Schlüssel in der Tabelle
/// `public.user_data`. Row Level Security stellt sicher, dass jeder nur seine
/// eigenen Zeilen sieht. Ohne Anmeldung tut der Speicher nichts.
class CloudStore {
  CloudStore(this.auth, {required this.appId});

  final AuthService auth;

  /// Kurzname der App, z. B. `prompt_arena`.
  final String appId;

  bool get active => auth.available && auth.loggedIn;

  /// Liest einen Wert; `null`, wenn nicht angemeldet oder nichts gespeichert
  /// ist. Ist der Server nicht erreichbar, wirft die Methode [AuthFailure],
  /// damit Apps nicht fälschlich "leer" annehmen und Daten überschreiben.
  Future<CloudEntry?> load(String key) async {
    if (!active) return null;
    try {
      final row = await auth.client
          .from('user_data')
          .select('value, updated_at')
          .eq('app', appId)
          .eq('key', key)
          .maybeSingle();
      if (row == null) return null;
      return CloudEntry(
        jsonEncode(row['value']),
        DateTime.parse(row['updated_at'] as String).toUtc(),
      );
    } catch (_) {
      throw const AuthFailure('Der Abgleich ist gerade nicht möglich.');
    }
  }

  /// Schreibt einen Wert (muss gültiges JSON sein). Gibt den Änderungszeitpunkt
  /// auf dem Server zurück, bei Fehlern oder ohne Anmeldung `null`.
  Future<DateTime?> save(String key, String json) async {
    if (!active) return null;
    try {
      final row = await auth.client
          .from('user_data')
          .upsert(
            {
              'user_id': auth.userId,
              'app': appId,
              'key': key,
              'value': jsonDecode(json),
            },
            onConflict: 'user_id,app,key',
          )
          .select('updated_at')
          .single();
      return DateTime.parse(row['updated_at'] as String).toUtc();
    } catch (_) {
      return null;
    }
  }
}
