<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    // Normalisasi data lama: status 'resolved'/'Resolved' → 'selesai',
    // dan kapitalisasi lain (Pending, Diproses, dll) → lowercase,
    // karena controller & UI hanya mendukung 4 status lowercase.
    public function up(): void
    {
        $map = [
            'resolved' => 'selesai',
            'Resolved' => 'selesai',
            'Pending' => 'pending',
            'Diproses' => 'diproses',
            'Selesai' => 'selesai',
            'Ditolak' => 'ditolak',
        ];

        foreach ($map as $from => $to) {
            DB::table('reports')->where('status', $from)->update(['status' => $to]);
            DB::table('report_updates')->where('status', $from)->update(['status' => $to]);
        }
    }

    public function down(): void
    {
        // Tidak perlu rollback: status adalah data operasional, bukan skema.
    }
};