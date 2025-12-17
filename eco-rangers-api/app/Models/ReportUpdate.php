<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReportUpdate extends Model
{
    use HasFactory;

    protected $fillable = [
        'report_id',
        'status',
        'keterangan',
        'nama_petugas',
        'foto_dokumentasi',
    ];

    /**
     * Mendapatkan laporan yang terkait dengan update ini.
     */
    public function report()
    {
        return $this->belongsTo(Report::class);
    }
}
