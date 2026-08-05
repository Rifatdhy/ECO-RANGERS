<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'judul', 'deskripsi', 'lokasi_text', 'lat', 'lng', 'foto_path', 'status'
    ];

    protected $appends = ['foto_url'];

    public function getFotoUrlAttribute()
    {
        // Jika foto_path sudah merupakan URL lengkap (dari seeder), langsung kembalikan.
        if (Str::startsWith($this->foto_path, ['http://', 'https://'])) {
            return $this->foto_path;
        }

        // Jika tidak, buat URL dari path di storage (untuk file upload sungguhan).
        return $this->foto_path
            ? url(Storage::url($this->foto_path))
            : null;
    }

    public function updates()
    {
        return $this->hasMany(ReportUpdate::class)->latest();
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    protected static function booted()
    {
        static::saving(function ($report) {
            $status = strtolower(trim($report->status ?: 'pending'));
            if ($status === 'resolved') {
                $status = 'selesai';
            }
            $report->status = $status;
        });
    }
}
