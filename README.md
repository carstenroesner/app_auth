# app_auth

Gemeinsame Nutzerverwaltung für alle Apps von Carsten Rösner (Flutter, Supabase Auth).

- Ohne Anmeldung arbeitet eine App rein lokal.
- Mit Konto (E-Mail + Passwort, Bestätigung per Mail-Link): angemeldet bleiben,
  Passwort vergessen, E-Mail-Adresse und Passwort ändern.
- `CloudStore` gleicht JSON-Daten pro Nutzer und App über Supabase (`public.user_data`, RLS) ab.

## Einbinden

```yaml
dependencies:
  app_auth:
    git:
      url: https://github.com/carstenroesner/app_auth
      ref: master
```

```dart
final auth = await AuthService.init();          // in main()
final cloud = CloudStore(auth, appId: 'meine_app');
openAccountScreen(context, auth, appName: 'Meine App');  // Menüpunkt "Konto"
```

Jede App bekommt bei jedem Build automatisch den neuesten Stand dieses Pakets
(kein `pubspec.lock` im Repo, nächtlicher Build in den Apps).
