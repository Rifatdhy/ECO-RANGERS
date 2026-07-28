# Testing Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build comprehensive test coverage across Laravel backend (PHPUnit + BDD) and Flutter frontend (unit, BDD, integration).

**Architecture:** Bottom-up: stabilize backend tests first (reliable API contract), then BDD cross-layer, then Flutter unit/integration/BDD.

**Tech Stack:** Laravel 11 + PHPUnit + Behat (BDD), Flutter 3.x + flutter_test + integration_test + flutter_gherkin (BDD)

## Global Constraints

- All Laravel tests use `RefreshDatabase` trait and `Sanctum::actingAs` for auth
- All Laravel tests run in SQLite in-memory (already configured in phpunit.xml)
- Flutter unit tests use `http.MockClient` from `package:http/testing.dart` — no real API calls
- Flutter integration tests use `IntegrationTestWidgetsFlutterBinding`
- BDD step definitions must reference actual `ValueKey` values from auth_page: `login-email`, `login-password`, `login-text`, `register-form`, `register-text`
- Existing tests that have bugs (wrong JSON structure, wrong field names) must be fixed, not deleted

---

### Task 1: Fix Existing Laravel PHPUnit Tests

**Files:**
- Modify: `eco-rangers-api/tests/Feature/ReportListTest.php` (all)
- Modify: `eco-rangers-api/tests/Feature/ReportStatusTest.php` (all)
- Modify: `eco-rangers-api/tests/Feature/AuthTest.php` (add test for failed login)

**Interfaces:**
- Consumes: `Report` model (fillable: user_id, judul, deskripsi, lokasi_text, lat, lng, foto_path, status), `User` model (is_admin field)
- Uses: Sanctum abilities (`role:admin`, `role:user`)

- [ ] **Step 1: Fix ReportListTest**

Current code has two bugs:
1. Response is paginated (`->paginate()`) but test expects top-level array
2. Field names `title`/`description` should be `judul`/`deskripsi`

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class ReportListTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_view_own_reports()
    {
        $user = User::factory()->create();
        Report::factory()->count(3)->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);
        $response = $this->getJson('/api/reports');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [['id', 'judul', 'deskripsi', 'status']]
        ]);
    }

    /** @test */
    public function admin_can_view_all_reports()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        User::factory()->count(2)->create()->each(function ($u) {
            Report::factory()->count(2)->create(['user_id' => $u->id]);
        });

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->getJson('/api/reports');

        $response->assertStatus(200);
        $response->assertJsonCount(4, 'data');
    }

    /** @test */
    public function unauthenticated_request_gets_empty_array()
    {
        $response = $this->getJson('/api/reports');
        $response->assertStatus(200);
        $response->assertJson([]);
    }
}
```

- [ ] **Step 2: Fix ReportStatusTest**

Change `actingAs($user, 'api')` to `Sanctum::actingAs($user, ['role:admin'])` since updateStatus requires admin ability:

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class ReportStatusTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function admin_can_update_report_status()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create(['status' => 'pending']);

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'selesai',
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment(['status' => 'Selesai']);
    }

    /** @test */
    public function non_admin_cannot_update_status()
    {
        $user = User::factory()->create();
        $report = Report::factory()->create(['status' => 'pending']);

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'selesai',
        ]);

        $response->assertStatus(403);
    }
}
```

- [ ] **Step 3: Add error-case tests to AuthTest**

```php
/** @test */
public function user_cannot_login_with_wrong_password()
{
    $user = User::factory()->create([
        'email' => 'test@example.com',
        'password' => bcrypt('correct'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => 'test@example.com',
        'password' => 'wrong',
    ]);

    $response->assertStatus(401)
             ->assertJson(['message' => 'Email atau password salah']);
}
```

- [ ] **Step 4: Run Laravel tests to verify**

```bash
cd eco-rangers-api && php artisan test
```
Expected: All tests pass (0 failures).

- [ ] **Step 5: Commit**

```bash
git add eco-rangers-api/tests/Feature/
git commit -m "test: fix existing Laravel PHPUnit tests and add error scenarios"
```

---

### Task 2: Add Laravel PHPUnit Tests — Admin & Edge Cases

**Files:**
- Create: `eco-rangers-api/tests/Feature/AdminTest.php`
- Modify: `eco-rangers-api/tests/Feature/RegisterTest.php` (add duplicate email test)

**Interfaces:**
- Admin endpoints: `POST /api/admin/clear-all-reports`, `DELETE /api/reports/{report}`
- Register endpoint: `POST /api/register` requires unique email and username

- [ ] **Step 1: Create AdminTest**

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function admin_can_delete_report()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create();

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->deleteJson("/api/reports/{$report->id}");

        $response->assertStatus(200)
                 ->assertJson(['deleted' => true]);
        $this->assertDatabaseMissing('reports', ['id' => $report->id]);
    }

    /** @test */
    public function non_admin_cannot_delete_report()
    {
        $user = User::factory()->create();
        $report = Report::factory()->create();

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->deleteJson("/api/reports/{$report->id}");

        $response->assertStatus(403);
    }

    /** @test */
    public function admin_can_clear_all_reports()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        Report::factory()->count(5)->create();

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->postJson('/api/admin/clear-all-reports');

        $response->assertStatus(200);
        $this->assertDatabaseCount('reports', 0);
    }

    /** @test */
    public function non_admin_cannot_clear_all_reports()
    {
        $user = User::factory()->create();
        Report::factory()->count(3)->create();

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->postJson('/api/admin/clear-all-reports');

        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_admin_endpoints()
    {
        $response = $this->deleteJson('/api/reports/1');
        $response->assertStatus(401);
    }
}
```

- [ ] **Step 2: Add duplicate email test to RegisterTest**

```php
/** @test */
public function cannot_register_with_duplicate_email()
{
    User::factory()->create(['email' => 'existing@example.com']);

    $data = [
        'username' => 'newuser',
        'email' => 'existing@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ];

    $response = $this->postJson('/api/register', $data);
    $response->assertStatus(422);
}
```

- [ ] **Step 3: Run tests**

```bash
cd eco-rangers-api && php artisan test
```

- [ ] **Step 4: Commit**

```bash
git add eco-rangers-api/tests/Feature/
git commit -m "test: add admin endpoint tests and registration edge cases"
```

---

### Task 3: Laravel BDD — Verify FeatureContext Implementations

**Files:**
- Read: `eco-rangers-api/features/bootstrap/FeatureContext.php`
- Modify (if needed): `eco-rangers-api/features/bootstrap/FeatureContext.php`

- [ ] **Step 1: Review FeatureContext for missing step definitions**

Check that every step in these feature files has a matching method in FeatureContext:
- `features/api/user_authentication.feature` (6 steps)
- `features/api/user_creates_report.feature`
- `features/api/user_views_reports.feature`
- `features/api/user_logout.feature`
- `features/api/admin_manages_reports.feature`

- [ ] **Step 2: Run Behat to verify**

```bash
cd eco-rangers-api && vendor/bin/behat
```
If any steps are undefined, add them to FeatureContext.

- [ ] **Step 3: Commit any fixes**

```bash
git add eco-rangers-api/features/
git commit -m "test: fix Laravel BDD step definitions"
```

---

### Task 4: Flutter Unit Tests — Model Tests

**Files:**
- Create: `test/models/laporan_test.dart`
- Create: `test/models/user_test.dart`

**Interfaces:**
- `Laporan.fromJson(Map<String, dynamic>)` — parses: id, judul, deskripsi, lokasi_text, lat, lng, foto_path, foto_url, status, created_at, updates, user
- `User.fromJson(Map<String, dynamic>)` — parses: id, name, username, email, is_admin (0/1/true/false)

- [ ] **Step 1: Create user_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses admin user with is_admin=1', () {
      final json = {
        'id': 1,
        'name': 'Admin',
        'username': 'admin',
        'email': 'admin@example.com',
        'is_admin': 1,
      };
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Admin');
      expect(user.isAdmin, true);
    });

    test('parses regular user with is_admin=0', () {
      final json = {
        'id': 2,
        'name': 'User',
        'username': 'user1',
        'email': 'user@example.com',
        'is_admin': 0,
      };
      final user = User.fromJson(json);
      expect(user.id, 2);
      expect(user.isAdmin, false);
    });

    test('parses is_admin as bool true', () {
      final json = {
        'id': 3,
        'name': 'Test',
        'username': 'test',
        'email': 'test@example.com',
        'is_admin': true,
      };
      final user = User.fromJson(json);
      expect(user.isAdmin, true);
    });

    test('handles missing fields with defaults', () {
      final json = {'id': 4};
      final user = User.fromJson(json);
      expect(user.name, '');
      expect(user.username, '');
      expect(user.email, '');
      expect(user.isAdmin, false);
    });
  });
}
```

- [ ] **Step 2: Create laporan_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/models/laporan.dart';
import 'package:eco_rangers/models/report_update.dart';

void main() {
  group('Laporan.fromJson', () {
    test('parses complete report JSON', () {
      final json = {
        'id': 1,
        'judul': 'Sampah di Sungai',
        'deskripsi': 'Banyak sampah plastik',
        'lokasi_text': 'Jakarta Selatan',
        'lat': -6.2,
        'lng': 106.8,
        'foto_path': 'reports/photo.jpg',
        'status': 'pending',
        'created_at': '2024-07-25T10:00:00',
        'updates': [],
        'user': {
          'id': 1,
          'name': 'User',
          'username': 'user1',
          'email': 'user@example.com',
          'is_admin': false,
        },
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.id, 1);
      expect(laporan.judul, 'Sampah di Sungai');
      expect(laporan.deskripsi, 'Banyak sampah plastik');
      expect(laporan.lokasiText, 'Jakarta Selatan');
      expect(laporan.latitude, -6.2);
      expect(laporan.longitude, 106.8);
      expect(laporan.fotoPath, 'reports/photo.jpg');
      expect(laporan.status, 'pending');
      expect(laporan.user, isNotNull);
      expect(laporan.user!.id, 1);
    });

    test('handles missing optional fields', () {
      final json = {
        'id': 2,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'status': 'diproses',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.id, 2);
      expect(laporan.latitude, isNull);
      expect(laporan.longitude, isNull);
      expect(laporan.lokasiText, 'Lokasi tidak tersedia');
      expect(laporan.fotoPath, isNull);
      expect(laporan.user, isNull);
      expect(laporan.updates, isEmpty);
    });

    test('uses defaults for missing judul/deskripsi', () {
      final json = {
        'id': 3,
        'status': 'selesai',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.judul, 'Tanpa Judul');
      expect(laporan.deskripsi, 'Tanpa Deskripsi');
    });

    test('parses lokasi from lat/lng when lokasi_text missing', () {
      final json = {
        'id': 4,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'lat': -7.5,
        'lng': 110.3,
        'status': 'pending',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.lokasiText, '-7.5, 110.3');
    });

    test('parses updates list', () {
      final json = {
        'id': 5,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'status': 'diproses',
        'created_at': '2024-07-25T10:00:00',
        'updates': [
          {
            'id': 1,
            'report_id': 5,
            'status': 'diproses',
            'keterangan': 'Sedang ditangani',
            'nama_petugas': 'Petugas A',
            'created_at': '2024-07-26T10:00:00',
          }
        ],
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.updates.length, 1);
      expect(laporan.updates[0].keterangan, 'Sedang ditangani');
    });
  });
}
```

- [ ] **Step 3: Run Flutter model tests**

```bash
flutter test test/models/
```
Expected: All pass.

- [ ] **Step 4: Commit**

```bash
git add test/models/
git commit -m "test: add Flutter model unit tests for User and Laporan"
```

---

### Task 5: Flutter Unit Tests — AuthService Test

**Files:**
- Create: `test/services/auth_service_test.dart`

**Interfaces:**
- `AuthService.instance` — singleton
- `login(email, password)` → `Future<User>`
- `register(username, email, password)` → `Future<Map<String, dynamic>>`
- `logout()` → `Future<void>`
- `getToken()` → `Future<String?>`
- `getMe()` → `Future<User?>`

Test uses `http.MockClient`. However, `AuthService` creates its own HTTP client. We need to inject a mock. The simplest approach: use `package:http/testing.dart` and override `http` client usage.

But `AuthService` directly uses `http.post()` — it doesn't use a configurable client. To test it, we either:
1. Refactor AuthService to accept an injectable HTTP client (better for testability)
2. Or test indirectly through higher-level integration

We'll take approach 1 (add client injection) to make it testable:

```dart
class AuthService {
  http.Client? _httpClient;
  
  AuthService({http.Client? httpClient}) : _httpClient = httpClient;
  
  http.Client get _client => _httpClient ?? http.Client();
  // use _client.post(...) instead of http.post(...)
}
```

- [ ] **Step 1: Refactor AuthService for dependency injection**

Edit `lib/services/auth_service.dart`:

```dart
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._({http.Client? httpClient}) : _httpClient = httpClient;
  static final AuthService instance = AuthService._();

  http.Client? _httpClient;
  
  http.Client get _client => _httpClient ?? http.Client();
```

Replace all `http.post(` with `_client.post(`, all `http.get(` with `_client.get(`.

- [ ] **Step 2: Update locator to pass default client**

```dart
locator.registerLazySingleton<AuthService>(() => AuthService.instance);
```
No change needed since instance has null client (uses default).

- [ ] **Step 3: Create auth_service_test.dart**

The refactored `AuthService` will have a `httpClient` setter for injection:

```dart
class AuthService {
  AuthService._();
  static AuthService instance = AuthService._();

  http.Client? _httpClient;

  set httpClient(http.Client? client) => _httpClient = client;

  http.Client get _client => _httpClient ?? http.Client();
}
```

Use a setter rather than constructor injection to preserve the singleton pattern.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('AuthService', () {
    setUp(() {
      AuthService.instance.httpClient = MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(jsonEncode({
            'token': 'test_token',
            'user': {'id': 1, 'name': 'Test', 'username': 'test', 'email': 'test@test.com', 'is_admin': false}
          }), 200);
        }
        if (request.url.path == '/api/register') {
          return http.Response(jsonEncode({
            'token': 'new_token',
            'user': {'id': 2, 'name': 'New', 'username': 'new', 'email': 'new@test.com', 'is_admin': false}
          }), 201);
        }
        return http.Response('Not found', 404);
      });
    });

    tearDown(() {
      AuthService.instance.httpClient = null;
    });

    test('login returns user on valid credentials', () async {
      final user = await AuthService.instance.login(
        email: 'test@test.com',
        password: 'password123',
      );
      expect(user.id, 1);
      expect(user.email, 'test@test.com');
      expect(user.isAdmin, false);
    });

    test('login throws on invalid credentials', () async {
      AuthService.instance.httpClient = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Email atau password salah'}), 401);
      });
      expect(
        () => AuthService.instance.login(email: 'x@x.com', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('register returns data on success', () async {
      final result = await AuthService.instance.register(
        username: 'newuser',
        email: 'new@test.com',
        password: 'password123',
      );
      expect(result['token'], 'new_token');
    });
  });
}
```

- [ ] **Step 4: Write full auth_service_test.dart**

Now write the same code from Step 3 into the actual file `test/services/auth_service_test.dart`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('AuthService', () {
    setUp(() {
      AuthService.instance.httpClient = MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(jsonEncode({
            'token': 'test_token',
            'user': {'id': 1, 'name': 'Test', 'username': 'test', 'email': 'test@test.com', 'is_admin': false}
          }), 200);
        }
        if (request.url.path == '/api/register') {
          return http.Response(jsonEncode({
            'token': 'new_token',
            'user': {'id': 2, 'name': 'New', 'username': 'new', 'email': 'new@test.com', 'is_admin': false}
          }), 201);
        }
        return http.Response('Not found', 404);
      });
    });

    tearDown(() {
      AuthService.instance.httpClient = null;
    });

    test('login returns user on valid credentials', () async {
      final user = await AuthService.instance.login(
        email: 'test@test.com',
        password: 'password123',
      );
      expect(user.id, 1);
      expect(user.email, 'test@test.com');
      expect(user.isAdmin, false);
    });

    test('login throws on invalid credentials', () async {
      AuthService.instance.httpClient = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Email atau password salah'}), 401);
      });
      expect(
        () => AuthService.instance.login(email: 'x@x.com', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('register returns data on success', () async {
      final result = await AuthService.instance.register(
        username: 'newuser',
        email: 'new@test.com',
        password: 'password123',
      );
      expect(result['token'], 'new_token');
    });
  });
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/services/
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/auth_service.dart test/services/
git commit -m "refactor: make AuthService HTTP client injectable for testing"
```

---

### Task 6: Flutter Unit Tests — ApiClient Test

**Files:**
- Create: `test/services/api_client_test.dart`

- [ ] **Step 1: Create api_client_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('ApiClient', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient();
    });

    test('getReports returns list on success', () async {
      // Inject mock — uses _request internally
      // ApiClient doesn't have injectable HTTP client yet
    });
  });
}
```

The `ApiClient` uses `http.Client()` internally and doesn't expose the client. We need to refactor:

```dart
class ApiClient {
  http.Client? _httpClient;
  
  set httpClient(http.Client client) => _httpClient = client;
  
  Future<http.Response> _request(...) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final client = _httpClient ?? http.Client();
        ...
      }
    }
  }
}
```

- [ ] **Step 2: Refactor ApiClient for injectable HTTP client**

Add `http.Client? _httpClient` field and setter. Update `_request` method to use `_httpClient ?? http.Client()`.

- [ ] **Step 3: Write api_client_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'token': 'test_token'});
    });

    test('getReports returns data on 200', () async {
      final apiClient = ApiClient();
      apiClient.httpClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token');
        return http.Response(
          jsonEncode([{'id': 1, 'judul': 'Test', 'deskripsi': 'Desc', 'status': 'pending', 'created_at': '2024-01-01T00:00:00'}]),
          200,
        );
      });

      final result = await apiClient.getReports();
      expect(result.length, 1);
    });

    test('getReports throws ApiException on server error', () async {
      final apiClient = ApiClient();
      apiClient.httpClient = MockClient((_) async {
        return http.Response('Error', 500);
      });

      expect(
        () => apiClient.getReports(),
        throwsA(isA<ApiException>()),
      );
    });

    test('deleteReport returns on success', () async {
      final apiClient = ApiClient();
      apiClient.httpClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response(jsonEncode({}), 200);
      });

      await apiClient.deleteReport(1);
    });

    test('deleteReport throws on not found', () async {
      final apiClient = ApiClient();
      apiClient.httpClient = MockClient((_) async {
        return http.Response('Not found', 404);
      });

      expect(
        () => apiClient.deleteReport(999),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/
```

- [ ] **Step 6: Commit**

```bash
git add lib/services/api_client.dart test/services/
git commit -m "refactor: make ApiClient HTTP client injectable for testing"
```

---

### Task 7: Flutter BDD — Implement test/steps/login_steps.dart

**Files:**
- Modify: `test/steps/login_steps.dart` (implement bodies)
- Verify: `features/login.feature` (ensure parameters match)

**Interfaces:**
- `features/login.feature` uses `{string}` parameters: `<username>`, `<password>`, `<outcome>`
- Login page has ValueKeys: `login-email`, `login-password`, `login-text` (button)
- Outcomes: "home page" or "error message"

- [ ] **Step 1: Check current auth_page keys match BDD assumptions**

Keys in auth_page: `login-email`, `login-password`, `login-text` (Masuk button text)
Feature file uses: `<username>`, `<password>` — but note: login uses email, not username!

The feature file should be updated or we accept the mismatch between feature file naming and actual UI (email field labeled "Email"). For testing, we enter the email value into the email field.

- [ ] **Step 2: Implement step bodies**

```dart
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter/material.dart';
import 'package:eco_rangers/main.dart' as app;

class GivenIAmOnTheLoginPage extends Given {
  @override
  Future<void> executeStep(World world) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I am on the login page');
}

class WhenIEnterMyUsernameAndPassword extends When2<String, String> {
  @override
  Future<void> executeStep(World world, String username, String password) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      username,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      password,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter my {string} and {string}');
}

class WhenITapTheLoginButton extends When {
  @override
  Future<void> executeStep(World world) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.tap(find.byKey(const ValueKey('login-text')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  @override
  RegExp get pattern => RegExp(r'I tap the login button');
}

class ThenIShouldSeeThe extends Then1<String> {
  @override
  Future<void> executeStep(World world, String outcome) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    if (outcome == 'home page') {
      expect(find.byType(DashboardUserPage), findsOneWidget);
    } else if (outcome == 'error message') {
      // SnackBar error — check for login failure text
      expect(find.byType(SnackBar), findsOneWidget);
    } else {
      throw Exception('Unknown outcome: $outcome');
    }
  }

  @override
  RegExp get pattern => RegExp(r'I should see the {string}');
}
```

Wait — the `test/steps/login_steps.dart` is for unit-test BDD (using `flutter_gherkin` with `FlutterWidgetTesterWorld`), while `integration_test/steps/login_steps.dart` is for integration-test BDD. Both use the same pattern.

Since these are BDD steps for `flutter_gherkin`, they need to be registered in the test runner. The feature file will be loaded by the Gherkin test runner config.

The key challenge: `DashboardUserPage` import. The test file is in `test/steps/` and needs to import `package:eco_rangers/pages/dashboard_user_page.dart`. This is fine since it's under `test/`.

Wait, but `flutter_gherkin` requires certain setup. Let me keep the implementations matching the pattern used in `integration_test/steps/login_steps.dart` which already works.

Let me simplify:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:eco_rangers/pages/dashboard_user_page.dart' as dashboard;
import 'package:eco_rangers/main.dart' as app;

class GivenIAmOnTheLoginPage extends Given {
  @override
  Future<void> executeStep(World world) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.pumpWidget(const app.EcoRangersApp());
  }

  @override
  RegExp get pattern => RegExp(r'I am on the login page');
}

class WhenIEnterMyUsernameAndPassword extends When2<String, String> {
  @override
  Future<void> executeStep(World world, String username, String password) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      username,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      password,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter my {string} and {string}');
}

class WhenITapTheLoginButton extends When {
  @override
  Future<void> executeStep(World world) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    await tester.tap(find.byKey(const ValueKey('login-text')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  @override
  RegExp get pattern => RegExp(r'I tap the login button');
}

class ThenIShouldSeeThe extends Then1<String> {
  @override
  Future<void> executeStep(World world, String outcome) async {
    final tester = (world as FlutterWidgetTesterWorld).rawAppTester;
    if (outcome == 'home page') {
      expect(find.byType(dashboard.DashboardUserPage), findsOneWidget);
    } else if (outcome == 'error message') {
      expect(find.text('Login gagal'), findsOneWidget);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I should see the {string}');
}
```

- [ ] **Step 3: Run BDD test**

```bash
flutter test features/
```
Expected: BDD step definitions registered and runnable.

- [ ] **Step 4: Commit**

```bash
git add test/steps/
git commit -m "test: implement Flutter BDD step definitions for login"
```

---

### Task 8: Flutter Integration Tests — Login & Navigation

**Files:**
- Create: `integration_test/report_flow_test.dart`
- Modify: `integration_test/login_test.dart` (expand with full scenarios)

- [ ] **Step 1: Expand login_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eco_rangers/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EcoRangers app launches and shows splash then auth page', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should see auth page (login form)
    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
  });

  testWidgets('Login form shows email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-text')), findsOneWidget);
  });

  testWidgets('Can switch between login and register tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find register tab and tap it
    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('register-form')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run integration tests**

```bash
flutter test integration_test/
```
Expected: All pass.

- [ ] **Step 3: Commit**

```bash
git add integration_test/
git commit -m "test: add Flutter integration tests for login and navigation"
```

---

### Task 9: Self-Review and Verification

- [ ] **Step 1: Run all Laravel tests**

```bash
cd eco-rangers-api && php artisan test
```

- [ ] **Step 2: Run all Flutter tests**

```bash
flutter test
```

- [ ] **Step 3: Run Flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 4: Fix any issues found**

- [ ] **Step 5: Final commit**

```bash
git add -A && git commit -m "test: complete testing foundation — Laravel PHPUnit + BDD + Flutter unit + BDD + integration"
```
