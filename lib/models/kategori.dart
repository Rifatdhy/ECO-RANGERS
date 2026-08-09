/// Kategori laporan — nilai lowercase sama dengan server, label untuk ditampilkan.
const List<({String value, String label, String icon})> reportCategories = [
  (value: 'sampah', label: 'Sampah', icon: '🗑️'),
  (value: 'pencemaran', label: 'Pencemaran', icon: '🏭'),
  (value: 'infrastruktur', label: 'Infrastruktur', icon: '🏗️'),
  (value: 'fauna', label: 'Fauna', icon: '🦎'),
  (value: 'flora', label: 'Flora', icon: '🌿'),
  (value: 'laimnya', label: 'Lainnya', icon: '📌'),
];

String kategoriLabel(String? value) {
  final v = (value ?? 'laimnya').toLowerCase();
  for (final c in reportCategories) {
    if (c.value == v) return c.label;
  }
  return 'Lainnya';
}

String kategoriIcon(String? value) {
  final v = (value ?? 'laimnya').toLowerCase();
  for (final c in reportCategories) {
    if (c.value == v) return c.icon;
  }
  return '📌';
}