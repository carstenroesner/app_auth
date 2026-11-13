import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_catalog.dart';
import 'auth_service.dart';

enum _Mode { login, register, forgot }

/// Anmelden, Registrieren, Passwort vergessen, E-Mail und Passwort ändern.
class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.auth,
    this.appName = 'diese App',
    this.showApps = false,
    this.returnUrl,
  });

  final AuthService auth;
  final String appName;

  /// Zeigt die Liste der angebundenen Apps (für das zentrale Konto-Portal).
  final bool showApps;

  /// Adresse der App, von der der Nutzer kam (nur eigene Apps erlaubt).
  final String? returnUrl;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  _Mode _mode = _Mode.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _newEmail = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;

  AuthService get auth => widget.auth;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _newEmail.dispose();
    super.dispose();
  }

  Future<void> _do(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final info = await action();
      if (mounted) setState(() => _info = info);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  String? _check({bool needPassword = true, bool newPassword = false}) {
    if (!_validEmail(_email.text)) {
      return 'Bitte eine gültige E-Mail-Adresse eingeben.';
    }
    if (needPassword && newPassword && _password.text.length < 8) {
      return 'Das Passwort braucht mindestens 8 Zeichen.';
    }
    if (needPassword && _password.text.isEmpty) return 'Bitte das Passwort eingeben.';
    return null;
  }

  Future<void> _submit() async {
    final problem = switch (_mode) {
      _Mode.login => _check(),
      _Mode.register => _check(newPassword: true),
      _Mode.forgot => _check(needPassword: false),
    };
    if (problem != null) {
      setState(() {
        _error = problem;
        _info = null;
      });
      return;
    }
    await _do(() async {
      switch (_mode) {
        case _Mode.login:
          await auth.signIn(_email.text, _password.text);
          _password.clear();
          return null;
        case _Mode.register:
          final pending = await auth.register(_email.text, _password.text);
          _password.clear();
          if (pending) {
            _mode = _Mode.login;
            return 'Fast geschafft: Wir haben dir eine Mail geschickt. Bitte den Link darin anklicken, danach kannst du dich anmelden.';
          }
          return null;
        case _Mode.forgot:
          await auth.sendPasswordReset(_email.text);
          _mode = _Mode.login;
          return 'Wenn es zu dieser Adresse ein Konto gibt, ist eine Mail mit einem Link zum Zurücksetzen unterwegs.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konto')),
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!auth.available)
                    _notice(context, 'Die Nutzerverwaltung ist gerade nicht erreichbar. ${widget.appName} arbeitet weiter lokal auf diesem Gerät.')
                  else if (auth.recoveryPending)
                    _recoveryForm(context)
                  else if (auth.loggedIn)
                    _accountView(context)
                  else
                    _loginForm(context),
                  if (widget.showApps) ..._appsSection(context),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 16),
                    _notice(context, _info!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _appsSection(BuildContext context) {
    final back = isAllowedReturnUrl(widget.returnUrl) ? widget.returnUrl! : null;
    final theme = Theme.of(context);
    return [
      if (back != null) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text('Zurück zur App'),
          onPressed: () => launchUrl(Uri.parse(back), webOnlyWindowName: '_self'),
        ),
      ],
      const Divider(height: 40),
      Text('Deine Apps', style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(auth.loggedIn
          ? 'Du bist angemeldet und kannst alle Apps nutzen.'
          : 'Alle Apps lassen sich auch ohne Konto nutzen, dann bleiben die Daten auf diesem Gerät.'),
      const SizedBox(height: 8),
      for (final app in appCatalog)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(app.name),
          subtitle: Text(app.description),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => launchUrl(Uri.parse(app.url), webOnlyWindowName: '_self'),
        ),
    ];
  }

  Widget _notice(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
    );
  }

  Widget _passwordField(String label, {TextEditingController? controller}) {
    return TextField(
      controller: controller ?? _password,
      obscureText: !_showPassword,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _showPassword ? 'Verbergen' : 'Anzeigen',
          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      onSubmitted: (_) => _busy ? null : _submit(),
    );
  }

  Widget _loginForm(BuildContext context) {
    final title = switch (_mode) {
      _Mode.login => 'Anmelden',
      _Mode.register => 'Konto anlegen',
      _Mode.forgot => 'Passwort vergessen',
    };
    final button = switch (_mode) {
      _Mode.login => 'Anmelden',
      _Mode.register => 'Konto anlegen',
      _Mode.forgot => 'Link zum Zurücksetzen senden',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Ohne Anmeldung bleiben alle Daten nur auf diesem Gerät. '
          'Mit Konto werden sie gesichert und auf allen deinen Geräten abgeglichen.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-Mail-Adresse', border: OutlineInputBorder()),
        ),
        if (_mode != _Mode.forgot) ...[
          const SizedBox(height: 12),
          _passwordField(_mode == _Mode.register ? 'Passwort (mindestens 8 Zeichen)' : 'Passwort'),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(button),
        ),
        const SizedBox(height: 8),
        if (_mode == _Mode.login) ...[
          TextButton(onPressed: () => _switch(_Mode.forgot), child: const Text('Passwort vergessen?')),
          TextButton(onPressed: () => _switch(_Mode.register), child: const Text('Noch kein Konto? Jetzt anlegen')),
        ] else
          TextButton(onPressed: () => _switch(_Mode.login), child: const Text('Zurück zur Anmeldung')),
      ],
    );
  }

  void _switch(_Mode mode) => setState(() {
        _mode = mode;
        _error = null;
        _info = null;
      });

  Widget _accountView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Angemeldet', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        SelectableText(auth.email ?? ''),
        const SizedBox(height: 4),
        const Text('Deine Daten werden gesichert und zwischen deinen Geräten abgeglichen.'),
        const Divider(height: 32),
        Text('E-Mail-Adresse ändern', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _newEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Neue E-Mail-Adresse', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () {
                  if (!_validEmail(_newEmail.text)) {
                    setState(() => _error = 'Bitte eine gültige E-Mail-Adresse eingeben.');
                    return;
                  }
                  _do(() async {
                    await auth.changeEmail(_newEmail.text);
                    _newEmail.clear();
                    return 'Wir haben eine Mail geschickt. Die neue Adresse gilt, sobald du den Link darin angeklickt hast.';
                  });
                },
          child: const Text('Adresse ändern'),
        ),
        const Divider(height: 32),
        Text('Passwort ändern', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _passwordField('Neues Passwort (mindestens 8 Zeichen)'),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () {
                  if (_password.text.length < 8) {
                    setState(() => _error = 'Das Passwort braucht mindestens 8 Zeichen.');
                    return;
                  }
                  _do(() async {
                    await auth.changePassword(_password.text);
                    _password.clear();
                    return 'Das Passwort wurde geändert.';
                  });
                },
          child: const Text('Passwort ändern'),
        ),
        const Divider(height: 32),
        FilledButton.tonal(
          onPressed: _busy ? null : () => _do(() async {
                await auth.signOut();
                return null;
              }),
          child: const Text('Abmelden'),
        ),
        const SizedBox(height: 8),
        const Text('Nach dem Abmelden bleiben die Daten auf diesem Gerät erhalten, werden aber nicht mehr abgeglichen.'),
      ],
    );
  }

  Widget _recoveryForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Neues Passwort festlegen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _passwordField('Neues Passwort (mindestens 8 Zeichen)'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_password.text.length < 8) {
                    setState(() => _error = 'Das Passwort braucht mindestens 8 Zeichen.');
                    return;
                  }
                  _do(() async {
                    await auth.changePassword(_password.text);
                    _password.clear();
                    return 'Das neue Passwort ist gespeichert, du bist angemeldet.';
                  });
                },
          child: const Text('Passwort speichern'),
        ),
      ],
    );
  }
}
