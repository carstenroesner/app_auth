import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'account_avatar.dart';
import 'auth_service.dart';
import 'user_profile.dart';

/// Größte erlaubte Bilddatei (nach dem Verkleinern).
const int maxAvatarBytes = 300 * 1024;

/// Vorname, Nachname und Profilbild bearbeiten.
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  Uint8List? _avatar;
  bool _dirty = false;
  bool _busy = false;
  String? _error;
  String? _info;

  AuthService get auth => widget.auth;

  @override
  void initState() {
    super.initState();
    _apply(auth.profile);
    auth.addListener(_onAuth);
  }

  @override
  void dispose() {
    auth.removeListener(_onAuth);
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _apply(UserProfile p) {
    _first.text = p.firstName;
    _last.text = p.lastName;
    _avatar = p.avatar;
  }

  /// Das Profil kommt kurz nach der Anmeldung vom Server. Solange der Nutzer
  /// nichts geändert hat, übernehmen wir es.
  void _onAuth() {
    if (!_dirty && mounted) setState(() => _apply(auth.profile));
  }

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > maxAvatarBytes) {
        if (mounted) setState(() => _error = 'Das Bild ist zu groß. Bitte ein kleineres wählen.');
        return;
      }
      if (mounted) {
        setState(() {
          _avatar = bytes;
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Das Bild konnte nicht geladen werden.');
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await auth.saveProfile(UserProfile(
        firstName: _first.text,
        lastName: _last.text,
        avatar: _avatar,
      ));
      if (mounted) {
        setState(() {
          _dirty = false;
          _info = 'Gespeichert. Das gilt in allen deinen Apps.';
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = UserProfile(
      firstName: _first.text,
      lastName: _last.text,
      avatar: _avatar,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Profil', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _preview(theme, preview),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_avatar == null ? 'Bild wählen' : 'Bild ändern'),
                    onPressed: _busy ? null : _pick,
                  ),
                  if (_avatar != null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _avatar = null;
                                _dirty = true;
                              }),
                      child: const Text('Bild entfernen'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _first,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          decoration: const InputDecoration(labelText: 'Vorname', border: OutlineInputBorder()),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _last,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.familyName],
          decoration: const InputDecoration(labelText: 'Nachname', border: OutlineInputBorder()),
          onChanged: (_) => setState(() => _dirty = true),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy || !_dirty ? null : _save,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Profil speichern'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (_info != null) ...[
          const SizedBox(height: 8),
          Text(_info!),
        ],
      ],
    );
  }

  /// Vorschau mit dem, was gerade eingegeben ist (noch nicht gespeichert).
  Widget _preview(ThemeData theme, UserProfile p) {
    final scheme = theme.colorScheme;
    if (p.avatar != null) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: MemoryImage(p.avatar!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        avatarLetters(p, auth.email),
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Großer Avatar mit Namen, für Konto-Bildschirme.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => Row(
        children: [
          AccountAvatar(auth: auth, radius: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auth.loggedIn && auth.profile.hasName)
                  Text(auth.profile.fullName, style: theme.textTheme.titleLarge),
                SelectableText(auth.email ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
