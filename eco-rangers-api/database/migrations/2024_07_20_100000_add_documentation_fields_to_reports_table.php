<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // No-op migration kept for historical compatibility.
        // The actual documentation fields are added in
        // 2025_09_16_000000_add_documentation_fields_to_reports_table.php.
        // To avoid accidental ALTER attempts when the `reports` table does
        // not yet exist (older migration timestamp), make this migration
        // explicitly a no-op.
        return;
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Defensive: only drop columns if the table and columns exist.
        if (! Schema::hasTable('reports')) {
            return;
        }

        $drops = array_filter(['nama_petugas', 'tanggal_pengerjaan', 'foto_dokumentasi'], function ($col) {
            return Schema::hasColumn('reports', $col);
        });

        if (! empty($drops)) {
            Schema::table('reports', function (Blueprint $table) use ($drops) {
                $table->dropColumn($drops);
            });
        }
    }
};
