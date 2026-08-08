<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_updates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained()->onDelete('cascade');
            // Anda bisa menambahkan foreignId ke user (admin) yang melakukan update jika perlu
            // $table->foreignId('user_id')->constrained();

            $table->string('status'); // Status baru (diproses, selesai, dll.)
            $table->text('keterangan')->nullable(); // Catatan dari admin
            $table->string('nama_petugas')->nullable();
            $table->string('foto_dokumentasi')->nullable();
            $table->timestamps(); // Ini akan menjadi tanggal update
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_updates');
    }
};
