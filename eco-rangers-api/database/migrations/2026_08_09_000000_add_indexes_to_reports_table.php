<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            if (! Schema::hasIndex('reports', 'reports_status_index')) {
                $table->index('status');
            }
            if (! Schema::hasIndex('reports', 'reports_user_id_index')) {
                $table->index('user_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            if (Schema::hasIndex('reports', 'reports_status_index')) {
                $table->dropIndex(['status']);
            }
            if (Schema::hasIndex('reports', 'reports_user_id_index')) {
                $table->dropIndex(['user_id']);
            }
        });
    }
};