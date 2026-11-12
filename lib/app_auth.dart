/// Gemeinsame Nutzerverwaltung für alle Apps (Supabase Auth + Cloud-Sync).
///
/// Ohne Anmeldung arbeiten Apps ausschließlich lokal. Mit Anmeldung (E-Mail
/// und Passwort) können Apps ihre Daten über [CloudStore] geräteübergreifend
/// abgleichen. Erweiterungen dieses Pakets kommen bei jedem neuen Build einer
/// App automatisch an.
library;

export 'src/account_screen.dart';
export 'src/auth_service.dart';
export 'src/cloud_store.dart';
