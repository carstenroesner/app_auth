import 'package:flutter/material.dart';

import 'app_account_screen.dart';
import 'auth_service.dart';
import 'user_profile.dart';

/// Runder Avatar: Bild, sonst Initialen, sonst Anfangsbuchstabe der
/// E-Mail-Adresse. Ohne Anmeldung zeigt er ein Schloss.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.auth, this.radius = 16});

  final AuthService auth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        if (!auth.loggedIn) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurfaceVariant,
            child: Icon(Icons.lock_outline, size: radius * 1.1),
          );
        }
        final avatar = auth.profile.avatar;
        if (avatar != null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: MemoryImage(avatar),
            onBackgroundImageError: (_, __) {},
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            avatarLetters(auth.profile, auth.email),
            style: TextStyle(
              fontSize: radius * 0.85,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

/// Avatar für die Titelleiste (rechts oben). Ein Tipp öffnet das Konto.
class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({
    super.key,
    required this.auth,
    this.appName = 'diese App',
  });

  final AuthService auth;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final tip = auth.loggedIn
            ? (auth.profile.hasName ? auth.profile.fullName : (auth.email ?? 'Konto'))
            : 'Nicht angemeldet';
        return Tooltip(
          message: tip,
          child: InkResponse(
            radius: 24,
            onTap: () => openAccountScreen(context, auth, appName: appName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AccountAvatar(auth: auth),
            ),
          ),
        );
      },
    );
  }
}
