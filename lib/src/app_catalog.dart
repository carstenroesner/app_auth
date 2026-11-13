/// Eine App, die die gemeinsame Nutzerverwaltung nutzt.
class AppEntry {
  const AppEntry(this.name, this.url, this.description);
  final String name;
  final String url;
  final String description;
}

/// Alle angebundenen Apps. Das Konto-Portal zeigt diese Liste an; neue Apps
/// werden hier eingetragen und erscheinen dadurch überall.
const List<AppEntry> appCatalog = [
  AppEntry(
    'Prompt Arena',
    'https://carstenroesner.github.io/prompt_arena/',
    'Prompts verwalten, sortieren und zwischen Geräten abgleichen.',
  ),
];

/// Nur Adressen der eigenen Apps (gleiche Herkunft wie das Portal) sind als
/// Rücksprungziel erlaubt.
bool isAllowedReturnUrl(String? url) {
  if (url == null) return false;
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'carstenroesner.github.io';
}
