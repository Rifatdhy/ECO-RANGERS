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
        Schema::table('users', function (Blueprint $table) {
            // Tambahkan kolom is_admin setelah kolom email
            // default(false) berarti user biasa secara default
            $table->boolean('is_admin')->after('email')->default(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Kode untuk menghapus kolom jika migrasi di-rollback
            $table->dropColumn('is_admin');
        });
    }
};
