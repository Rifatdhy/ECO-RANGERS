<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'judul','deskripsi','lokasi_text','lat','lng','foto_path','status'
    ];

    // supaya ikut tampil di JSON
    protected $appends = ['foto_url'];

    public function getFotoUrlAttribute()
    {
        return $this->foto_path
            ? url(Storage::url($this->foto_path))
            : null;
    }

    // Tambahan agar status selalu valid untuk enum
    protected static function booted()
    {
        static::creating(function ($report) {
            if ($report->status) {
                $report->status = strtolower($report->status);
            } else {
                $report->status = 'pending';
            }
        });
    }
}
