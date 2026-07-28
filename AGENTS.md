# AGENTS.md — Eco Rangers

## Project Overview

Flutter mobile app + Laravel API backend for environmental-issue reporting. The Flutter app lives at the repo root (`lib/`, `pubspec.yaml`); the Laravel API lives in `eco-rangers-api/`.

## Structure

| Path | Purpose |
|------|---------|
| `lib/` | Flutter app (Dart) — entrypoints, pages, services, models, UI |
| `eco-rangers-api/` | Laravel PHP backend (routes, controllers, models, migrations, seeders) |
| `test/` | Flutter unit + widget tests + BDD step definitions |
| `integration_test/` | Flutter integration tests + step definitions |
| `features/` | BDD `.feature` gherkin files |
| `android/`, `ios/`, `web/` | Platform build output (do not edit manually) |

## Developer Commands

### Backend (Laravel)
```bash
cd eco-rangers-api
composer install                          # install PHP deps
cp .env.example .env && php artisan key:generate
php artisan migrate --seed                # sets up default admin (admin@gmail.com / 12345678)
php artisan serve --host=0.0.0.0 --port=8000  # must use 0.0.0.0 for emulator access
php artisan test                          # run all backend tests (SQLite in-memory)
```

### Frontend (Flutter)
```bash
flutter pub get                           # install Dart deps
# Create .env at repo root with: API_BASE_URL=http://10.0.2.2:8000
flutter run                               # run on connected device/emulator
flutter test                              # unit + widget tests
flutter test integration_test/            # integration tests
flutter test features/                    # BDD gherkin tests (flutter_gherkin)
flutter analyze                           # lint (uses flutter_lints)
```

## Key Quirks & Gotchas

- **`.env` at repo root** — `flutter_dotenv` loads `fileName: ".env"` from the Flutter app root. The `pubspec.yaml` lists `.env` as an asset so it's bundled. A `.env.example` exists at root with a sample `API_BASE_URL`.
- **API base URL** — set in `lib/config.dart` via `ensureBaseUrl()`. Falls back to `localhost:8000` if dotenv is empty. For Android emulator use `10.0.2.2:8000`; for physical device use your LAN IP.
- **`--host=0.0.0.0` required** — `php artisan serve` must bind to `0.0.0.0` for the emulator or physical device to reach the API.
- **Test setup duplication** — every test entrypoint (`test/app_test.dart`, `integration_test/app.dart`, `integration_test/steps/login_steps.dart`) manually calls `dotenv.load`, `setupLocator()`, and `ensureBaseUrl()`. Adding a new test file requires these three lines.
- **SQLite in-memory for Laravel tests** — `phpunit.xml` sets `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:`. No persistent database for backend tests.
- **`uuid` override** — `pubspec.yaml` has `dependency_overrides: uuid: ^4.0.0` because `flutter_gherkin` depends on an older uuid constraint.
- **Sanctum auth** — API routes use `auth:sanctum` middleware. The `ability:role:admin` middleware gates admin-only endpoints.
- **Image serving** — photos are served via `/api/files/{path}` proxy route in `routes/api.php`, not directly from storage. The `imageUrlFrom()` helper in `config.dart` builds these URLs from `foto_path` or `foto_url` fields.
- **Testing seeder routes** — `POST /api/testing/seed-admin` and `POST /api/testing/reset` are only active in `local`/`testing` environments. Do not deploy to production.
- **BDD tests** — step definitions in `test/steps/login_steps.dart` and `integration_test/steps/login_steps.dart` now have working implementations using `WidgetTester`. The feature file `features/login.feature` has a scenario outline ready for execution.
- **DevicePreview** — enabled in debug mode (`!kReleaseMode`) for responsive preview. `lib/main.dart` wraps the app with `DevicePreview`.
- **Typed exceptions** — `ApiClient` uses `ApiException` and `NetworkException` instead of generic `Exception` for better error handling.
- **HTTP timeouts** — all HTTP calls have a 15-second timeout with automatic retry (up to 2 attempts).
- **Splash auth check** — `SplashScreen` now checks for existing auth token and redirects directly to the dashboard if the user is logged in.
- **Removed dead code** — `lib/services/report_api.dart` was deleted (duplicate of `ApiClient.getReports()`).
- **Removed unused deps** — `sqflite`, `path`, `shimmer`, and `flutter_driver` were removed from `pubspec.yaml`.
- **API pagination** — `ReportController::index()` now supports `page` and `per_page` query params (max 100 per page).

## Architecture Patterns

- **GetIt DI** — `lib/locator.dart` registers `AuthService` and `ApiClient` as lazy singletons. `lib/main.dart` calls `setupLocator()` before `runApp`.
- **API client** — `lib/services/api_client.dart` handles HTTP; `lib/services/auth_service.dart` handles auth.
- **Config** — `lib/config.dart` exports `baseUrl`, `api()` (URI builder), and `imageUrlFrom()` (image URL helper).

## File Conventions

- Dart files use `lowerCamelCase` filenames (e.g., `api_client.dart`, `buat_laporan_page.dart`).
- PHP files follow PSR-4 autoloading under `eco-rangers-api/app/`.
- BDD feature files in `features/` use Gherkin syntax.
- `.env` files are gitignored (except `.env.example` is committed).

---

## 🧠 Session Memory — Resume Context

> **Last session:** 2026-07-29 — Semua fix P0/P1/P2 selesai + runtime verification + path traversal fix + UX polish.

### Test Status
| Layer | Count | Status |
|-------|-------|--------|
| Flutter test | 19/19 | ✅ |
| Flutter analyze | 0 err, 0 warn, 6 info | ✅ |
| Laravel test | 16/16 (41 assertions) | ✅ |
| Runtime (curl) | register, login, reports, status, rate-limit, CORS, path traversal | ✅ |

### All Fixes Applied

| # | Issue | File | Type |
|---|-------|------|------|
| 1 | `.gitignore` ignored `storage`, `vendor`, `.env` | `.gitignore` | P0 |
| 2 | `APP_KEY` exposed in repo | `.env` → key:generate | P0 |
| 3 | CORS `allow_all_origins: true` | `cors.php` | P0 |
| 4 | Sanctum token never expired | `sanctum.php` | P0 |
| 5 | 3 no-op migration files | `2025_*_*_*_create_*_table.php` | P0 |
| 6 | `checkIn()` foreign key in `users` migration | migration | P0 |
| 7 | `.env.testing` trailing garbage | `.env.testing` | P0 |
| 8 | `http.Client` leak in `_request` | `api_client.dart` | P0 |
| 9 | Splash `initState` duplicate `_checkAuth` | `splash_screen.dart` | P0 |
| 10 | Admin detail `//` bypass URL validation | `detail_laporan_admin_page.dart` | P0 |
| 11 | Redundant `login()` after `register()` | `auth_service.dart` | P1 |
| 12 | DI bypass in `DaftarLaporanPage` | `daftar_laporan_page.dart` | P1 |
| 13 | `StatusConfig` utility + unify 4 pages | `status_config.dart` | P1 |
| 14 | Auth controllers manual password check | `AuthController`, `AdminAuthController` | P1 |
| 15 | Path traversal via `Storage::path` | `routes/api.php` | P1 |
| 16 | `ReportFactory` broken | `ReportFactory.php` | P1 |
| 17 | Rate limiting on auth routes | `routes/api.php` | P1 |
| 18 | Redundant `foto_url` override | controller | P1 |
| 19 | Multi-device login (no token delete) | `AuthController` | P1 |
| 20 | `updateStatus()` request mutation | `update_status_page.dart` → `api_client.dart` | P2 |
| 21 | Status casing mutator/accessor | `Report.php` | P2 |
| 22 | Minor fixes (email validation, force-unwrap, dotenv, BDD dedup, dead files) | various | P2 |

### Current Session Fixes (2026-07-29)

| # | Fix | Files Changed |
|---|-----|---------------|
| A | `GET /api/reports` di luar `auth:sanctum` → `$request->user()` null | `routes/api.php`, `ReportListTest.php` |
| B | `getReports()` cast `as List` crash on paginated Map | `api_client.dart` |
| C | Path traversal stack trace bocor | `routes/api.php` |
| D | Error messages raw `e.toString()` ke user | `dashboard_user_page.dart`, `dashboard_admin_page.dart`, `detail_laporan_admin_page.dart`, `api_reports_page.dart`, `daftar_laporan_page.dart`, `update_status_page.dart` |
| E | 3 redundant filter mechanism (search + bottom sheet + choice chips) | `dashboard_user_page.dart`, `dashboard_admin_page.dart` |
| F | Button style inconsistent (`ElevatedButton` vs `FilledButton`) | `detail_laporan_admin_page.dart`, `update_status_page.dart` |

### Remaining Info-level Issues (not blocking)
- `desiredAccuracy` deprecated → use `settings` param — `buat_laporan_page.dart:57`
- `use_build_context_synchronously` — `laporan_detail_page.dart:39,57`
- `background` → `surface` — `laporan_detail_page.dart:259`, `splash_screen.dart:96`
- `value` → `initialValue` — `update_status_page.dart:132`
- `ApiReportsPage` (`api_reports_page.dart`) — dead code, not referenced anywhere
- WhatsApp number hardcoded in `buat_laporan_page.dart:114`

### Key Architecture Decisions (don't revert)
- ✅ Auth route `GET /api/reports` **wajib** `auth:sanctum`
- ✅ Admin detect via `tokenCan('role:admin')`, bukan `is_admin`
- ✅ Pagination response `{data: [...], current_page, ...}` — client extract `['data']`
- ✅ Filter status dikirim lowercase, ChoiceChips sebagai satu-satunya filter UI
- ✅ Tombol action utama pakai `FilledButton` (seragam)
- ✅ Error user-facing pakai `e is ApiException ? e.message : fallback`
- ✅ Foto via proxy `/api/files/{path}`, bukan langsung dari storage

### Resume Entry Points
- **Want to continue fixing**: buka `AGENTS.md` → cek "Remaining Issues" di atas
- **Want to add feature**: baca `## Architecture Patterns` lalu cek routing di `routes/api.php`
- **Want to debug**: jalankan `flutter test && cd eco-rangers-api && php artisan test`
- **Want to deploy**: pastikan `cors.php`, `sanctum.php`, `.env` sudah production-safe