<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Pastikan tabel 'reports' ada sebelum mengubahnya (mencegah kegagalan
        // saat migrasi dijalankan pada lingkungan baru dan urutan file tidak
        // sempurna).
        if (! Schema::hasTable('reports')) {
            return;
        }

        Schema::table('reports', function (Blueprint $table) {
            // Tambahkan user_id setelah kolom id.
            // onDelete('set null') berarti jika user dihapus, laporannya tidak ikut terhapus,
            // hanya user_id-nya menjadi null.
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn('user_id');
        });
    }
};
