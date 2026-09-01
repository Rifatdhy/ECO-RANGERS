# Eco Rangers - Wireframe FINAL Handoff

Wireframe: wireframe-final.html (390x844 iOS frosted, paper #FFFBF5 dot 20px, tape 86x20, rotate halus)

## Tokens
- lib/ui/tokens.dart: forest #1E3A2A, moss #2F6B4A, clay #C98A6A, sand #E8D9C5, line #E5DDD3, paper #FFFBF5
- radius 12/14/16/36, bg #F2F2F7
- brandGradient forest->moss

## Shell
- lib/pages/main_shell.dart: NavigationBar height 56, indicator moss 12%, FAB 56 forest

## Pages -> Wireframe
- Splash -> splash_screen.dart
- Auth -> auth_page.dart (POST /login admin@gmail.com/12345678)
- Home -> home_page.dart (KPI 128/14, chips, ReportCard border line)
- Peta -> map_page.dart (flutter_map)
- Buat Laporan -> buat_laporan_page.dart (image_picker resize, GPS -6.20,106.84)
- Detail -> laporan_detail_page.dart (timeline vote/confirm)
- Aktivitas -> activity_page.dart
- Notifikasi -> notifikasi_page.dart
- Profil -> profile_page.dart (secure_storage)
- Admin -> dashboard_admin_page.dart (fl_chart CSV signed)

## API
POST /register, /login, /admin/login throttle 5/menit; GET /reports; POST /reports; POST /reports/{id}/vote|confirm; PATCH /reports/{id}/status; GET /admin/export
