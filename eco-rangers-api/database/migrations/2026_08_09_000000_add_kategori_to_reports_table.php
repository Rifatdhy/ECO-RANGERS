<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->enum('kategori', [
                'sampah',
                'pencemaran',
                'infrastruktur',
                'fauna',
                'flora',
                'laimnya',
            ])->default('laimnya')->after('judul');
        });
    }

    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->dropColumn('kategori');
        });
    }
};