<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class CsvExportTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function unauthenticated_request_is_rejected(): void
    {
        $this->get('/api/admin/export/reports')->assertStatus(403);
    }

    #[Test]
    public function export_has_bom_no_store_and_sanitized_cells(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        Report::factory()->create([
            'user_id' => $admin->id,
            'judul' => '=SUM(1,1)',
            'status' => 'selesai',
        ]);
        $token = $admin->createToken('csv-export', ['role:admin'])->plainTextToken;

        $urlRes = $this->withToken($token)
            ->get('/api/admin/export/reports/url')
            ->assertOk();
        $signedUrl = $urlRes->json('url');

        $response = $this->get(parse_url($signedUrl, PHP_URL_PATH) . '?' . parse_url($signedUrl, PHP_URL_QUERY));

        $response->assertHeader('Cache-Control');
        $cc = $response->headers->get('Cache-Control');
        $this->assertStringContainsString('no-store', $cc);
        $this->assertStringContainsString('private', $cc);

        $content = $response->streamedContent();
        $this->assertStringStartsWith("\xEF\xBB\xBF", $content);
        $this->assertStringContainsString("'=SUM(1,1)", $content);
    }

    #[Test]
    public function signed_url_is_required_and_expired_links_are_rejected(): void
    {
        $this->get('/api/admin/export/reports')->assertStatus(403);

        $admin = User::factory()->create(['is_admin' => true]);
        $token = $admin->createToken('csv-export', ['role:admin'])->plainTextToken;
        $this->withToken($token)
            ->get('/api/admin/export/reports/url')
            ->assertOk();

        $payload = base64_encode(json_encode(['s' => 'semua', 'k' => 'semua', 'q' => null]));
        $exp = now()->subMinute()->getTimestamp();
        $sig = hash_hmac('sha256', $payload . '.' . $exp, config('app.key'));
        $this->get('/api/admin/export/reports?p=' . urlencode($payload) . '&e=' . $exp . '&sig=' . $sig)
            ->assertStatus(403);
    }
}
