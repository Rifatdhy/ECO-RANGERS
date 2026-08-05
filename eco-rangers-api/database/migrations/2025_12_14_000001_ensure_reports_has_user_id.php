<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // BUKAN duplikat: di fresh install, 2024_07_26_000100_add_user_id_to_reports_table
    // berjalan sebelum create_reports (2025_09_15) sehingga guard hasTable()-nya
    // early-return. Migrasi ini yang benar-benar menambahkan user_id.
    public function up(): void
    {
        if (! Schema::hasTable('reports')) return;

        if (! Schema::hasColumn('reports', 'user_id')) {
            Schema::table('reports', function (Blueprint $table) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('set null');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('reports') && Schema::hasColumn('reports', 'user_id')) {
            Schema::table('reports', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
                $table->dropColumn('user_id');
            });
        }
    }
};
