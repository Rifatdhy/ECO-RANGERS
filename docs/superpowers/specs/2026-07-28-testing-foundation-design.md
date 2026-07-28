# Testing Foundation — Design Spec

**Project:** Eco Rangers (Flutter + Laravel)
**Sub-project:** 1 of 5
**Goal:** Establish comprehensive test coverage across all layers — backend (Laravel PHPUnit + BDD), frontend (Flutter unit, BDD, integration).

## Architecture

Bottom-up approach: stabilize backend testing first (reliable API contract), then BDD cross-layer, then Flutter unit/integration/BDD.

## Layer 1: Laravel PHPUnit

- Extend 7 existing feature tests with error scenarios (validation failures, unauthorized, not found)
- Add admin-only endpoint tests (updateStatus, deleteReport, clearAll)
- Add input validation tests (empty fields, invalid email, short password)
- Keep pattern: `RefreshDatabase`, `Sanctum::actingAs`, `assertJsonStructure`, `assertStatus`

## Layer 2: Laravel BDD (Behat)

- Verify FeatureContext.php (728 lines) has all step definitions for 5 feature files
- Run Behat suite to confirm all scenarios pass
- Fix any missing or broken step definitions

## Layer 3: Flutter Unit Tests

| File | Coverage |
|------|----------|
| `test/models/laporan_test.dart` | `Laporan.fromJson` — parse all fields, null safety, edge cases |
| `test/models/user_test.dart` | `User.fromJson` — is_admin as bool (0/1/true/false) |
| `test/services/api_client_test.dart` | Mock HTTP — getReports, createReport, updateStatus, delete, timeout, retry |
| `test/services/auth_service_test.dart` | Login, register, logout, token persistence, getMe |

Key: Use `http.MockClient` from `package:http/testing.dart` — no real API calls.

## Layer 4: Flutter BDD (Gherkin)

- Implement empty bodies in `test/steps/login_steps.dart` (inject WidgetTester via FlutterWidgetTesterWorld)
- Audit ValueKey usage in auth_page to ensure step definitions match actual widget keys
- Fix `features/login.feature` parameter names if needed

## Layer 5: Flutter Integration Tests

| Test | Description |
|------|-------------|
| Login flow | Email/password → login → dashboard |
| Register flow | Tab register → form → register → dashboard |
| Navigation | Tab switching, drawer, back navigation |

Pattern: `IntegrationTestWidgetsFlutterBinding`, `pumpAndSettle` for animation wait.
