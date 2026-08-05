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

    protected static function booted()
    {
        static::saving(function ($update) {
            $status = strtolower(trim($update->status ?: ''));
            if ($status === 'resolved') {
                $status = 'selesai';
            }
            $update->status = $status;
        });
    }
}
