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

        $response = $this->get('/api/admin/export/reports?token=' . $token);

        $response->assertHeader('Cache-Control');
        $cc = $response->headers->get('Cache-Control');
        $this->assertStringContainsString('no-store', $cc);
        $this->assertStringContainsString('private', $cc);

        $content = $response->streamedContent();
        $this->assertStringStartsWith("\xEF\xBB\xBF", $content);
        $this->assertStringContainsString("'=SUM(1,1)", $content);
    }
}
