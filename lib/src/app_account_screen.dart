import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';

/// Konto-Bildschirm innerhalb einer App: zeigt den Anmeldestatus und führt
/// zum zentralen Konto-Portal, wo Anmeldung und Kontoverwaltung stattfinden.
/// Die Anmeldung gilt in allen Apps.
Future<void> openAccountScreen(
  BuildContext context,
  AuthService auth, {
  String appName = 'diese App',
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AppAccountScreen(auth: auth, appName: appName),
    ),
  );
}

class AppAccountScreen extends StatelessWidget {
  const AppAccountScreen({super.key, required this.auth, this.appName = 'diese App'});

  final AuthService auth;
  final String appName;

  Future<void> _openPortal() {
    final from = kIsWeb ? Uri.base.removeFragment().replace(query: '').toString() : null;
    final uri = Uri.parse(accountPortalUrl).replace(
      queryParameters: {if (from != null) 'from': from},
    );
    return launchUrl(uri, webOnlyWindowName: '_self');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konto')),
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final theme = Theme.of(context);
          final String title;
          final String text;
          final String button;
          if (!auth.available) {
            title = 'Nicht erreichbar';
            text = 'Die Nutzerverwaltung ist gerade nicht erreichbar. $appName arbeitet weiter lokal auf diesem Gerät.';
            button = '';
          } else if (auth.loggedIn) {
            title = 'Angemeldet';
            text = '${auth.email ?? ''}\n\nDeine Daten werden gesichert und zwischen deinen Geräten abgeglichen. Die Anmeldung gilt in allen deinen Apps.';
            button = 'Konto verwalten';
          } else {
            title = 'Nicht angemeldet';
            text = 'Ohne Anmeldung bleiben alle Daten nur auf diesem Gerät. Mit einem Konto werden sie gesichert und auf allen deinen Geräten abgeglichen. Das Konto gilt für alle deine Apps.';
            button = 'Anmelden oder Konto anlegen';
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  SelectableText(text),
                  if (button.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _openPortal, child: Text(button)),
                  ],
                  if (auth.available && auth.loggedIn) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => auth.signOut(),
                      child: const Text('Abmelden'),
                    ),
                    const Text(
                      'Nach dem Abmelden bleiben die Daten auf diesem Gerät erhalten, werden aber nicht mehr abgeglichen.',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
