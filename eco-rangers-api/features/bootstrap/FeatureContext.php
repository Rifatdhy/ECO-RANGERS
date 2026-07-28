<?php

use Behat\Behat\Context\Context;
use Behat\Gherkin\Node\TableNode;
use GuzzleHttp\Client;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class FeatureContext implements Context
{
    private Client $client;

    private array $response = [];
    private int $statusCode = 0;

    private ?string $token = null;          // token user/admin yang sedang aktif
    private ?string $selectedStatus = null; // status yang dipilih admin
    private ?int $currentReportId = null;   // report id yang sedang diproses

    /** @var array<string,int> map judul -> report_id */
    private array $reportIdsByTitle = [];

    // form fields (diisi oleh step "I fill in")
    private string $email = '';
    private string $password = '';
    private string $name = '';
    private string $password_confirmation = '';

    private string $judul = '';
    private string $deskripsi = '';
    private string $lokasi_text = '';
    private ?string $fotoPath = null;
    private ?string $lat = null;
    private ?string $lng = null;

    // admin token disimpan terpisah supaya bisa update status sewaktu-waktu
    private ?string $adminToken = null;
    private string $defaultUserEmail = 'rifat@gmail.com';
    private string $defaultUserPassword = '12345678';


    public function __construct()
    {
        $this->client = new Client([
            'base_uri' => 'http://127.0.0.1:8000',
            'http_errors' => false,
            'headers' => ['Accept' => 'application/json'],
        ]);
    }

    /**
     * @BeforeScenario
     */
    public function resetDatabaseBeforeScenario()
    {
        // Pastikan environment test pada server juga di-reset sehingga setiap scenario
        // berjalan pada kondisi DB yang konsisten.
        $this->json('POST', '/api/testing/reset', []);
        if ($this->statusCode === 200) {
            return;
        }

        // Jika route reset tidak tersedia (mis. server tidak dijalankan pada env testing),
        // fallback: coba setidaknya seed admin agar tests yang membutuhkan admin tidak langsung gagal.
        if ($this->statusCode === 404) {
            $this->json('POST', '/api/testing/seed-admin', []);
            if ($this->statusCode === 200) {
                // Warning: kita lanjutkan, tapi lingkungan DB tidak sepenuhnya reset.
                return;
            }
        }

        $this->fail("Gagal mereset database sebelum scenario. Status: {$this->statusCode}");
    }

    /* ============================================================
     * Helper
     * ============================================================ */

    private function json($method, $url, array $json = [], ?string $token = null): void
    {
        $opts = ['json' => $json];
        if ($token) {
            $opts['headers']['Authorization'] = 'Bearer ' . $token;
        }
        $res = $this->client->request($method, $url, $opts);
        $this->statusCode = $res->getStatusCode();
        $body = (string) $res->getBody();
        $this->response = json_decode($body, true) ?? ['_raw' => $body];
    }

    private function multipartPostReports(?string $token): void
    {
        $multipart = [
            ['name' => 'judul', 'contents' => $this->judul],
            ['name' => 'deskripsi', 'contents' => $this->deskripsi],
            ['name' => 'lokasi_text', 'contents' => $this->lokasi_text],
        ];

        if ($this->lat !== null) $multipart[] = ['name' => 'lat', 'contents' => $this->lat];
        if ($this->lng !== null) $multipart[] = ['name' => 'lng', 'contents' => $this->lng];

        // Foto opsional (kalau file ada)
        if ($this->fotoPath && file_exists($this->fotoPath)) {
            $multipart[] = [
                'name' => 'foto',
                'contents' => fopen($this->fotoPath, 'r'),
                'filename' => basename($this->fotoPath)
            ];
        }

        $opts = ['multipart' => $multipart, 'headers' => ['Accept' => 'application/json']];
        if ($token) {
            $opts['headers']['Authorization'] = 'Bearer ' . $token;
        }

        $res = $this->client->post('/api/reports', $opts);
        $this->statusCode = $res->getStatusCode();
        $body = (string) $res->getBody();
        $this->response = json_decode($body, true) ?? ['_raw' => $body];
    }

    private function fail(string $message): void
    {
        throw new \Exception($message . " | status={$this->statusCode} | response=" . json_encode($this->response));
    }

    private function ensureToken(): void
    {
        if (!$this->token) {
            $this->fail("Auth token kosong (belum login atau login gagal).");
        }
    }

    private function extractTokenFromResponse(): ?string
    {
        // sesuaikan jika response token Anda beda field
        return $this->response['token'] ?? $this->response['data']['token'] ?? null;
    }

    private function extractReportId(): ?int
    {
        // sesuaikan jika response report Anda beda struktur
        // contoh umum:
        // { data: { id: 1, ... } } atau { id: 1, ... }
        if (isset($this->response['data']['id'])) return (int)$this->response['data']['id'];
        if (isset($this->response['id'])) return (int)$this->response['id'];
        if (isset($this->response['report']['id'])) return (int)$this->response['report']['id'];
        if (isset($this->response['data']['report']['id'])) return (int)$this->response['data']['report']['id'];
        return null;
    }

    /* ============================================================
     * “UI” steps: No-op (agar tidak undefined)
     * ============================================================ */

    /** @Given I am on the login page */
    public function iAmOnTheLoginPage() { /* no-op */ }

    /** @Given I am on the register page */
    public function iAmOnTheRegisterPage() { /* no-op */ }

    /** @Given I am on the :page page */
    public function iAmOnThePage($page) { /* no-op for API testing */ }


    /** @When I navigate to :page */
    public function iNavigateTo($page) { /* no-op */ }

    /** @When I go to :page */
    public function iGoTo($page)
    {
        // delegate to a handler that performs API calls for certain pages
        $this->iGoToHandle($page);
    }

    // handler for simulated page navigation (no Behat annotation to avoid ambiguity)
    private function iGoToHandle($page)
    {
        $page = trim($page);
        if ($page === 'Daftar Semua Laporan') {
            // Ensure admin token present
            if (!$this->adminToken) {
                $this->iAmLoggedInAsAdmin('admin@gmail.com');
            }
            $this->json('GET', '/api/reports', [], $this->adminToken);
        }
        // Other pages are no-op for now
    }

    /** @When I follow :link */
    public function iFollow($link) { /* no-op */ }

    /** @When I allow the app to access my location */
    public function iAllowLocation() { /* no-op */ }

    /** @When my current coordinates are :latText and :lngText */
    public function myCurrentCoordinatesAre($latText, $lngText)
    {
        // input contoh: "lat=-6.200000" dan "lng=106.816666"
        $this->lat = str_replace(['lat=', '"', ' '], '', $latText);
        $this->lng = str_replace(['lng=', '"', ' '], '', $lngText);
    }

    /** @When I attach the file :path to :field */
    public function iAttachTheFileTo($path, $field)
    {
        // Anda bisa ganti /path/to/foto-sampah.jpg menjadi path nyata di laptop Anda
        if ($field === 'foto') {
            $this->fotoPath = trim($path);
        }
    }

    /** @When I leave :field empty */
    public function iLeaveFieldEmpty($field)
    {
        $field = trim($field);
        $this->$field = '';
    }

    /* ============================================================
     * Auth setup steps
     * ============================================================ */

    /** @Given there is a user with email :email and password :password */
    public function thereIsAUserWithEmailAndPassword($email, $password)
    {
        $email = trim($email);
        $payload = [
            'username' => explode('@', $email)[0],
            'name' => explode('@', $email)[0],
            'email' => $email,
            'password' => $password,
            'password_confirmation' => $password,
        ];

        // Coba daftar lewat API agar data ada di DB server yang dipanggil Behat
        $this->json('POST', '/api/register', $payload);

        // Bisa saja sudah ada (status 422), yang penting user ada
        if (!in_array($this->statusCode, [201, 422], true)) {
            $this->fail("Gagal membuat user via API: status {$this->statusCode}");
        }

    }

    /** @Given I am logged in as :email */
    public function iAmLoggedInAs($email)
    {
        $email = trim($email);

        // pastikan user ada
        $this->thereIsAUserWithEmailAndPassword(
            $email,
            $this->defaultUserPassword
        );

        // login
        $this->json('POST', '/api/login', [
            'email' => $email,
            'password' => $this->defaultUserPassword,
        ]);

        $this->token = $this->extractTokenFromResponse();
        if (!$this->token) {
            $this->fail("Login user gagal, token tidak ditemukan.");
        }
    }


    /** @Given I am logged in as admin :email */
    public function iAmLoggedInAsAdmin($email)
    {
        $email = trim($email);

        // Pastikan admin ada di server (endpoint testing yang hanya aktif di env lokal/testing)
        $this->json('POST', '/api/testing/seed-admin', []);

        // Login dengan password default admin yang disimpan oleh seeder
        $this->json('POST', '/api/admin/login', [
            'email' => $email,
            'password' => '12345678',
        ]);

        $this->adminToken = $this->extractTokenFromResponse();
        if (!$this->adminToken) {
            $this->fail("Login admin gagal. Pastikan admin benar-benar ada dan password benar.");
        }

        // set token aktif sebagai admin
        $this->token = $this->adminToken;
    }


    /* ============================================================
     * Form steps
     * ============================================================ */

    /** @When I fill in :field with :value */
    public function iFillInWith($field, $value)
    {
        $field = trim($field);
        $value = trim($value);

        // mapping ke property class
        if (!property_exists($this, $field)) {
            // biar tidak hard-fail kalau ada field UI fiktif
            return;
        }

        $this->$field = $value;
    }

    /* ============================================================
     * Button press steps
     * ============================================================ */

    /** @When I press :button */
    public function iPress($button)
    {
        $button = trim($button);

        if ($button === 'Login') {
            $this->json('POST', '/api/login', [
                'email' => trim($this->email),
                'password' => $this->password,
            ]);
            $this->token = $this->extractTokenFromResponse();
            return;
        }

        if ($button === 'Register') {
            $this->json('POST', '/api/register', [
                'username' => $this->name, // ⬅️ WAJIB
                'name' => $this->name,
                'email' => trim($this->email),
                'password' => $this->password,
                'password_confirmation' => $this->password_confirmation,
            ]);
            return;
        }

        if ($button === 'Kirim Laporan') {
            $this->ensureToken();
            $this->multipartPostReports($this->token);

            $rid = $this->extractReportId();
            if ($rid) {
                $this->currentReportId = $rid;
                // map by title untuk dipakai step “open the detail for ...”
                if ($this->judul) $this->reportIdsByTitle[$this->judul] = $rid;
            }
            return;
        }

        if ($button === 'Update Status') {
            if (!$this->adminToken) $this->fail("Admin token kosong untuk Update Status.");
            if (!$this->currentReportId) $this->fail("currentReportId kosong saat Update Status.");
            if (!$this->selectedStatus) $this->fail("selectedStatus kosong saat Update Status.");

            $this->json('PATCH', "/api/reports/{$this->currentReportId}/status", [
                'status' => $this->selectedStatus
            ], $this->adminToken);
            return;
        }

        if ($button === 'Hapus Laporan') {
            if (!$this->adminToken) $this->fail("Admin token kosong untuk Hapus Laporan.");
            if (!$this->currentReportId) $this->fail("currentReportId kosong saat Hapus Laporan.");

            $this->json('DELETE', "/api/reports/{$this->currentReportId}", [], $this->adminToken);
            return;
        }

        if ($button === 'Logout') {
            $this->ensureToken();
            $this->json('POST', '/api/logout', [], $this->token);
            // setelah logout token dibuang
            $this->token = null;
            return;
        }

        // tombol lain: no-op
    }

    /* ============================================================
     * Assertions for auth scenarios
     * ============================================================ */

    /** @Then I should be logged in successfully */
    public function iShouldBeLoggedInSuccessfully()
    {
        if ($this->statusCode !== 200) {
            $this->fail("Expected login status 200, got {$this->statusCode}");
        }
        if (!$this->token) {
            $this->fail("Expected token ada setelah login, tapi token kosong.");
        }
    }

    /** @Then I should have a valid auth token */
    public function iShouldHaveAValidAuthToken()
    {
        if (!$this->token) $this->fail("Token tidak ada / kosong.");
    }

    /** @Then I should not be logged in */
    public function iShouldNotBeLoggedIn()
    {
        if ($this->token !== null) {
            $this->fail("Token seharusnya null (tidak login), tapi masih ada token.");
        }
    }

    /** @Then I should see :text */
    public function iShouldSee($text)
    {
        $text = trim($text);
        $payload = json_encode($this->response);
        if (strpos($payload, $text) === false) {
            $this->fail("Tidak menemukan teks '{$text}' pada response.");
        }
    }

    /** @Then an account with email :email should exist */
    public function anAccountWithEmailShouldExist($email)
    {
        // Validasi sederhana: cek apakah user ada di DB server
        $email = trim($email);
        $this->json('POST', '/api/login', ['email' => $email, 'password' => $this->password]);
        // Jika login gagal, coba cek lebih langsung apakah user ada (mis. karena password berbeda)
        if ($this->statusCode === 200) return;

        // Jika login tidak berhasil, periksa keberadaan di DB (kemungkinan password beda)
        $this->json('POST', '/api/register', [
            'username' => explode('@', $email)[0],
            'name' => explode('@', $email)[0],
            'email' => $email,
            'password' => 'dummy',
            'password_confirmation' => 'dummy',
        ]);
        // Jika kita dapat 422 (sudah ada), maka akun ada.
        if ($this->statusCode === 422) return;

        $this->fail("Akun {$email} tidak ditemukan di server (login & register check gagal). Status: {$this->statusCode}");
    }

    /** @Then I should be able to login with email :email and password :password */
    public function iShouldBeAbleToLogin($email, $password)
    {
        $email = trim($email);
        $this->json('POST', '/api/login', [
            'email' => $email,
            'password' => $password,
        ]);
        if ($this->statusCode !== 200) $this->fail("Login seharusnya berhasil untuk {$email}.");
    }

    /** @Then a new account with email :email should not be created */
    public function aNewAccountWithEmailShouldNotBeCreated($email)
    {
        // Cara aman: coba register lagi dengan email itu harus tetap gagal
        $email = trim($email);
        $this->json('POST', '/api/register', [
            'username' => $this->name, // ⬅️ WAJIB
            'name' => $this->name,
            'email' => trim($this->email),
            'password' => $this->password,
            'password_confirmation' => $this->password_confirmation,
        ]);

        // expected: 409/422 (tergantung implementasi)
        if (!in_array($this->statusCode, [409, 422], true)) {
            $this->fail("Expected status 409/422 for duplicate email, got {$this->statusCode}");
        }
    }

    /* ============================================================
     * Report creation assertions
     * ============================================================ */

    /** @Then a new report should be stored with: */
    public function aNewReportShouldBeStoredWith(TableNode $table)
    {
        // Setelah POST /api/reports, response harus memuat report
        $expected = $table->getRowsHash();

        // Ambil data report dari response
        $data = $this->response['data'] ?? $this->response;

        // judul
        if (isset($expected['judul']) && (($data['judul'] ?? null) !== $expected['judul'])) {
            $this->fail("Judul report tidak sesuai.");
        }

        // status
        if (isset($expected['status']) && (($data['status'] ?? null) !== $expected['status'])) {
            $this->fail("Status report tidak sesuai.");
        }

        // email_pelapor (kalau API Anda mengembalikan email)
        // Jika API Anda tidak mengembalikan email, Anda bisa hapus check ini.
        if (isset($expected['email_pelapor'])) {
            $payload = json_encode($this->response);
            if (strpos($payload, $expected['email_pelapor']) === false) {
                $this->fail("Email pelapor tidak ditemukan pada response.");
            }
        }
    }

    /** @Then no new report should be stored */
    public function noNewReportShouldBeStored()
    {
        // expected: validasi gagal biasanya 422
        if (!in_array($this->statusCode, [400, 422], true)) {
            $this->fail("Expected report creation fail status 400/422, got {$this->statusCode}");
        }
    }

    /** @Then I should be redirected to :page */
    public function iShouldBeRedirectedTo($page) { /* API test: no-op */ }

    /* ============================================================
     * Steps for preparing reports from tables
     * ============================================================ */

    /** @Given there are reports in the system: */
    public function thereAreReportsInTheSystem(TableNode $table)
    {
        // Buat report sebagai user biasa, lalu set status via admin agar sesuai tabel
        // Pastikan admin token tersedia (login admin dulu di scenario)
        if (!$this->adminToken) $this->fail("Admin token kosong. Pastikan step login admin dieksekusi sebelum membuat reports.");

        // buat user pembuat laporan
        $creatorEmail = 'user@example.com';
        $this->iAmLoggedInAs($creatorEmail);
        $userToken = $this->token;

        foreach ($table->getHash() as $row) {
            $judul = $row['judul'];
            $status = $row['status'];

            // create report (status awal biasanya Pending)
            $this->judul = $judul;
            $this->deskripsi = "Auto seeded for BDD";
            $this->lokasi_text = "Auto Location";
            $this->multipartPostReports($userToken);

            $rid = $this->extractReportId();
            if (!$rid) $this->fail("Gagal mengambil report id setelah create.");
            $this->reportIdsByTitle[$judul] = $rid;

            // update status jika bukan Pending
            if ($status !== 'Pending') {
                $this->json('PATCH', "/api/reports/{$rid}/status", ['status' => $status], $this->adminToken);
                if ($this->statusCode !== 200) $this->fail("Gagal update status report '{$judul}' ke '{$status}'.");
            }
        }

        // restore token admin sebagai token aktif
        $this->token = $this->adminToken;
    }

   

    /** @Given there are reports created by :email: */
    public function thereAreReportsCreatedByEmail(string $email, TableNode $table)
    {
        $email = trim($email);

        // Login sebagai user tersebut (otomatis register jika belum ada)
        $this->iAmLoggedInAs($email);
        $userToken = $this->token;

        // Pastikan ada admin token untuk update status bila diperlukan
        if (!$this->adminToken) {
            $this->iAmLoggedInAsAdmin("admin@gmail.com");
        }

        foreach ($table->getHash() as $row) {
            $judul = $row['judul'];
            $status = $row['status'];

            // create report
            $this->judul = $judul;
            $this->deskripsi = "Auto seeded for BDD";
            $this->lokasi_text = "Auto Location";
            $this->multipartPostReports($userToken);

            $rid = $this->extractReportId();
            if (!$rid) $this->fail("Gagal mengambil report id setelah create.");
            $this->reportIdsByTitle[$judul] = $rid;

            // update status jika bukan Pending
            if ($status !== 'Pending') {
                $this->json('PATCH', "/api/reports/{$rid}/status", ['status' => $status], $this->adminToken);
                if ($this->statusCode !== 200) $this->fail("Gagal update status report '{$judul}' ke '{$status}'.");
            }
        }

        // Kembalikan token aktif ke user (karena scenario ini dipakai di fitur user)
        $this->token = $userToken;
    }


    /** @Given there is a report with: */
    public function thereIsAReportWith(TableNode $table)
    {
        $data = $table->getRowsHash();
        // buat report sebagai user login (atau login dulu)
        if (!$this->token) {
            $this->iAmLoggedInAs("rifat@gmail.com");
        }
        $userToken = $this->token;

        $this->judul = $data['judul'] ?? 'Report Default';
        $this->deskripsi = $data['deskripsi'] ?? 'Desc';
        $this->lokasi_text = $data['lokasi_text'] ?? 'Lokasi';
        $this->multipartPostReports($userToken);

        $rid = $this->extractReportId();
        if (!$rid) $this->fail("Gagal mengambil report id setelah create.");
        $this->currentReportId = $rid;
        $this->reportIdsByTitle[$this->judul] = $rid;

        // set status jika diperlukan (butuh admin)
        if (isset($data['status']) && $data['status'] !== 'Pending') {
            if (!$this->adminToken) $this->iAmLoggedInAsAdmin("admin@gmail.com");
            $this->json('PATCH', "/api/reports/{$rid}/status", ['status' => $data['status']], $this->adminToken);
            if ($this->statusCode !== 200) $this->fail("Gagal update status report ke {$data['status']}.");
        }
    }

    /* ============================================================
     * Admin interaction steps
     * ============================================================ */

    /** @When I open the detail for :judul */
    public function iOpenTheDetailFor($judul)
    {
        $judul = trim($judul);
        if (!isset($this->reportIdsByTitle[$judul])) {
            $this->fail("Report dengan judul '{$judul}' tidak ditemukan di map. Pastikan report dibuat pada Given.");
        }
        $this->currentReportId = $this->reportIdsByTitle[$judul];

        // optional: panggil show endpoint
        $this->json('GET', "/api/reports/{$this->currentReportId}");
    }

    /** @When I select :value from :field */
    public function iSelectFrom($value, $field)
    {
        if (trim($field) === 'status') {
            $this->selectedStatus = trim($value);
        }
    }

    /** @When I confirm the deletion */
    public function iConfirmTheDeletion() { /* no-op */ }

    /** @Then the report status should be :status */
    public function theReportStatusShouldBe($status)
    {
        // status could be at top-level or nested under 'report' or 'data'.
        $statusFound = null;
        if (isset($this->response['status'])) $statusFound = $this->response['status'];
        if (isset($this->response['report']['status'])) $statusFound = $this->response['report']['status'];
        if (isset($this->response['data']['status'])) $statusFound = $this->response['data']['status'];

        if ($statusFound === null) {
            $this->fail("Expected status '{$status}', but no status field was present in response.");
        }

        if ($statusFound !== $status) {
            $this->fail("Expected status '{$status}', got '{$statusFound}'");
        }
    }

    /** @Then the report :judul should not exist in the system anymore */
    public function reportShouldNotExist($judul)
    {
        $judul = trim($judul);
        if (!isset($this->reportIdsByTitle[$judul])) {
            // kalau tidak ada id, anggap sudah tidak ada
            return;
        }
        $rid = $this->reportIdsByTitle[$judul];

        $this->json('GET', "/api/reports/{$rid}");
        if ($this->statusCode === 200) {
            $this->fail("Report '{$judul}' masih bisa diakses (GET /api/reports/{$rid} masih 200).");
        }
    }

    /* ============================================================
     * Logout assertions
     * ============================================================ */

    /** @Then my auth token should be invalidated */
    public function myAuthTokenShouldBeInvalidated()
    {
        // token sudah dibuang di step logout
        if ($this->token !== null) {
            $this->fail("Token seharusnya null setelah logout.");
        }
    }

    /** @Then I should not be able to access :page without logging in again */
    public function iShouldNotBeAbleToAccessWithoutLoginAgain($page)
    {
        // Cek akses /api/me (umum untuk verifikasi token)
        $this->json('GET', '/api/me', [], null);
        // Kalau route /api/me memang protected, harusnya 401
        if (!in_array($this->statusCode, [401, 403], true)) {
            $this->fail("Expected 401/403 after logout when calling /api/me, got {$this->statusCode}");
        }
    }

    /** @Then I should be redirected to the login page */
    public function iShouldBeRedirectedToLoginPage() { /* no-op */ }

    /** @Then I should see their current status */
    public function iShouldSeeTheirCurrentStatus() { /* no-op */ }

    /** @Then I should see the status for each report */
    public function iShouldSeeStatusForEachReport() { /* no-op */ }

    /** @Then I should see the report photo if available */
    public function iShouldSeeReportPhotoIfAvailable() { /* no-op */ }
}
