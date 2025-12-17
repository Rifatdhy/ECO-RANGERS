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
        Schema::table('reports', function (Blueprint $table) {
            $table->string('nama_petugas')->nullable()->after('status');
            $table->date('tanggal_pengerjaan')->nullable()->after('nama_petugas');
            $table->string('foto_dokumentasi')->nullable()->after('tanggal_pengerjaan');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->dropColumn(['nama_petugas', 'tanggal_pengerjaan', 'foto_dokumentasi']);
        });
    }
};
