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
  AppEntry(
    'Tanita Anzeige',
    'https://carstenroesner.github.io/tanita_anzeige/',
    'Analysedaten der Tanita-Waage anzeigen und zwischen Geräten abgleichen.',
  ),
  AppEntry(
    'GC Winterberg Birdie Book',
    'https://carstenroesner.github.io/gc-winterberg-birdie-book/',
    'Digitales Birdie Book für den 9-Loch-Turnierplatz des GC Winterberg.',
  ),
  AppEntry(
    'SprayTattoo Katalog',
    'https://carstenroesner.github.io/spraytattoo_katalog/',
    'Katalog für Spraytattoo-Vorlagen mit Wunschliste und Bestell-Ablauf.',
  ),
  AppEntry(
    'Point & Click Adventure',
    'https://carstenroesner.github.io/pack/',
    'Eigene Engine für ein Point-and-Click-Adventure im SCUMM-Stil.',
  ),
  AppEntry(
    'Spook',
    'https://carstenroesner.github.io/spook/',
    'Flutter-Projekt (in Arbeit).',
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
