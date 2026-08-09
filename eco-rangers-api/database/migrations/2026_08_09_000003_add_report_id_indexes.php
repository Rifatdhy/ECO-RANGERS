<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Index pokok: query via report_id (whereHas/eager) tanpa full scan.
        // user_id pada kedua tabel sudah ter-index oleh FK.
        Schema::table('report_updates', function (Blueprint $table) {
            if (! Schema::hasIndex('report_updates', 'report_updates_report_id_index')) {
                $table->index('report_id');
            }
        });

        Schema::table('votes', function (Blueprint $table) {
            if (! Schema::hasIndex('votes', 'votes_report_id_index')) {
                $table->index('report_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('report_updates', function (Blueprint $table) {
            if (Schema::hasIndex('report_updates', 'report_updates_report_id_index')) {
                $table->dropIndex(['report_id']);
            }
        });

        Schema::table('votes', function (Blueprint $table) {
            if (Schema::hasIndex('votes', 'votes_report_id_index')) {
                $table->dropIndex(['report_id']);
            }
        });
    }
};