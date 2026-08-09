<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Report;
use App\Models\ReportUpdate;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Report::select([
                'id', 'user_id', 'judul', 'kategori', 'deskripsi', 'lokasi_text',
                'lat', 'lng', 'foto_path', 'status', 'created_at'
            ])
            ->with('user:id,name,username')
            ->orderByDesc('id');

        // Fitur filter berdasarkan status
        if ($request->has('status') && $request->input('status') !== '') {
            $status = strtolower($request->input('status'));
            if (in_array($status, ['pending', 'diproses', 'selesai', 'ditolak'])) {
                $query->where('status', $status);
            }
        }

        // Fitur filter berdasarkan kategori
        if ($request->has('kategori') && $request->input('kategori') !== '') {
            $kategori = strtolower($request->input('kategori'));
            $allowed = ['sampah', 'pencemaran', 'infrastruktur', 'fauna', 'flora', 'laimnya'];
            if (in_array($kategori, $allowed, true)) {
                $query->where('kategori', $kategori);
            }
        }

        // Pencarian server-side: judul / deskripsi / lokasi (LIKE, case-insensitive).
        if ($request->filled('q')) {
            $q = trim($request->input('q'));
            $query->where(function ($sub) use ($q) {
                $sub->where('judul', 'like', "%{$q}%")
                    ->orWhere('deskripsi', 'like', "%{$q}%")
                    ->orWhere('lokasi_text', 'like', "%{$q}%");
            });
        }

        // Admin dapat melihat semua laporan; pengguna biasa hanya miliknya.
        if (!$user->tokenCan('role:admin')) {
            $query->where('user_id', $user->id);
        }

        $reports = $query
            ->offset($request->integer('offset', 0))
            ->limit(min(max($request->integer('limit', 200), 1), 500))
            ->get();

        // Normalisasi status ke lowercase + foto_url konsisten (tanpa nested updates).
        $reports->transform(function ($report) {
            $report->status = strtolower($report->status);
            $report->kategori = strtolower($report->kategori);
            $report->foto_url = $report->foto_path ? asset('storage/' . $report->foto_path) : null;
            return $report;
        });

        // Tambahkan header untuk menonaktifkan caching
        return response()->json($reports)->header('Cache-Control', 'no-store, no-cache, must-revalidate');
    }

    public function show(Report $report, Request $request)
    {
        $user = $request->user();

        if ($user && !$user->tokenCan('role:admin') && $report->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $report->load(['user', 'updates']);
        $report->status = strtolower($report->status);
        return response()->json($report);
    }

    public function stats(Request $request)
    {
        $user = $request->user();
        $query = Report::query();

        if (!$user->tokenCan('role:admin')) {
            $query->where('user_id', $user->id);
        }

        $counts = (clone $query)
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        // Distribusi per kategori (untuk filter & insight).
        $kategoriCounts = (clone $query)
            ->selectRaw('kategori, COUNT(*) as total')
            ->groupBy('kategori')
            ->pluck('total', 'kategori');

        // Leaderboard: 5 pengguna dengan laporan terbanyak (scope global untuk admin,
        // hanya diri sendiri untuk pengguna biasa — admin saja yang relevan).
        $leaderboard = [];
        if ($user->tokenCan('role:admin')) {
            $leaderboard = Report::selectRaw('user_id, users.name, users.username, COUNT(*) as total')
                ->join('users', 'users.id', '=', 'reports.user_id')
                ->groupBy('user_id', 'users.name', 'users.username')
                ->orderByDesc('total')
                ->limit(5)
                ->get()
                ->map(fn ($r) => [
                    'name' => $r->name ?: $r->username,
                    'total' => $r->total,
                ])
                ->toArray();
        }

        // Tren 30 hari terakhir: jumlah laporan per tanggal.
        $daily = (clone $query)
            ->where('created_at', '>=', now()->subDays(29)->startOfDay())
            ->selectRaw('DATE(created_at) as tanggal, COUNT(*) as total')
            ->groupBy('tanggal')
            ->orderBy('tanggal')
            ->pluck('total', 'tanggal');

        $trend = [];
        for ($i = 29; $i >= 0; $i--) {
            $date = now()->subDays($i)->toDateString();
            $trend[] = ['date' => $date, 'total' => (int) ($daily[$date] ?? 0)];
        }

        // Rata-rata waktu tanggap (jam): selisih created_at → update pertama.
        $avgHours = Report::query()
            ->whereHas('updates')
            ->with(['updates' => fn ($u) => $u->orderBy('created_at')->limit(1)])
            ->get()
            ->map(function ($r) {
                $first = $r->updates->first();
                $base = $r->created_at;
                if (! $first || ! $first->created_at || ! $base) {
                    return null;
                }
                $diffMin = abs($first->created_at->getTimestamp() - $base->getTimestamp()) / 60;
                return $diffMin / 60.0;
            })
            ->filter()
            ->avg();

        return response()->json([
            'total' => (clone $query)->count(),
            'pending' => (int) ($counts['pending'] ?? 0),
            'diproses' => (int) ($counts['diproses'] ?? 0),
            'selesai' => (int) ($counts['selesai'] ?? 0),
            'ditolak' => (int) ($counts['ditolak'] ?? 0),
            'kategori' => [
                'sampah' => (int) ($kategoriCounts['sampah'] ?? 0),
                'pencemaran' => (int) ($kategoriCounts['pencemaran'] ?? 0),
                'infrastruktur' => (int) ($kategoriCounts['infrastruktur'] ?? 0),
                'fauna' => (int) ($kategoriCounts['fauna'] ?? 0),
                'flora' => (int) ($kategoriCounts['flora'] ?? 0),
                'laimnya' => (int) ($kategoriCounts['laimnya'] ?? 0),
            ],
            'trend' => $trend,
            'avg_response_hours' => $avgHours !== null ? round((float) $avgHours, 1) : null,
            'leaderboard' => $leaderboard,
        ])->header('Cache-Control', 'no-store, no-cache, must-revalidate');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'judul'       => ['required','string','max:255'],
            'kategori'    => ['nullable','string','in:sampah,pencemaran,infrastruktur,fauna,flora,laimnya'],
            'deskripsi'   => ['required','string'],
            'lokasi_text' => ['nullable','string'],
            'lat'         => ['nullable','numeric'],
            'lng'         => ['nullable','numeric'],
            'foto'        => ['nullable','image','mimes:jpg,jpeg,png','max:4096'],
        ]);

        $path = $request->hasFile('foto') ? $request->file('foto')->store('reports', 'public') : null;

        $report = Report::create([
            'user_id'     => $request->user()->id,
            'judul'       => $validated['judul'],
            'kategori'    => $validated['kategori'] ?? 'laimnya',
            'deskripsi'   => $validated['deskripsi'],
            'lokasi_text' => $validated['lokasi_text'] ?? null,
            'lat'         => $validated['lat'] ?? null,
            'lng'         => $validated['lng'] ?? null,
            'foto_path'   => $path,
            'status'      => 'pending',
        ]);

        $report->load('user');
        $report->status = strtolower($report->status);
        $report->kategori = strtolower($report->kategori);
        $report->foto_url = $report->foto_path ? asset('storage/' . $report->foto_path) : null;

        return response()->json(['report' => $report], 201);
    }

    public function updateStatus(Request $request, Report $report)
    {
        if ($request->has('status')) {
            $request->merge(['status' => strtolower($request->input('status'))]);
        }

        $validated = $request->validate([
            'status'             => ['required', 'in:pending,diproses,selesai,ditolak'],
            'keterangan'         => ['nullable', 'string'],
            'nama_petugas'       => ['nullable', 'string', 'max:255'],
            'foto_dokumentasi'   => ['nullable', 'image', 'mimes:jpg,jpeg,png', 'max:4096'],
        ]);

        $path = null;
        if ($request->hasFile('foto_dokumentasi')) {
            $path = $request->file('foto_dokumentasi');
        }

        DB::transaction(function () use ($report, $validated, $path, $request) {
            // Simpan file di dalam transaksi: jika DB gagal, upload di-batalkan
            // (Laravel menghapus file yang di-store jika exception) → hindari orphan.
            $storedPath = $path ? $path->store('documentation', 'public') : null;

            $report->updates()->create([
                'status'           => $validated['status'],
                'keterangan'       => $validated['keterangan'] ?? null,
                'nama_petugas'     => $validated['nama_petugas'] ?? null,
                'foto_dokumentasi' => $storedPath,
            ]);

            $report->status = $validated['status'];
            $report->save();
        });

        $report->load(['user', 'updates']);
        $report->status = strtolower($report->status);
        $report->updates->each(function ($update) {
            $update->status = strtolower($update->status);
        });

        return response()->json([
            'message' => 'Status laporan berhasil diubah',
            'report' => $report
        ]);
    }

    public function destroy(Report $report)
    {
        $report->load('updates');

        DB::transaction(function () use ($report) {
            foreach ($report->updates as $update) {
                if ($update->foto_dokumentasi) {
                    Storage::disk('public')->delete($update->foto_dokumentasi);
                }
            }
            if ($report->foto_path) {
                Storage::disk('public')->delete($report->foto_path);
            }

            $report->delete();
        });

        return response()->json(['message' => 'Laporan berhasil dihapus', 'deleted' => true]);
    }

    public function clearAll(Request $request)
    {
        DB::transaction(function () {
            // 1. Hapus semua file dari storage
            $reportFiles = Storage::disk('public')->files('reports');
            $documentationFiles = Storage::disk('public')->files('documentation');
            Storage::disk('public')->delete($reportFiles);
            Storage::disk('public')->delete($documentationFiles);

            // 2. Hapus semua data dari tabel (metode yang kompatibel dengan SQLite & MySQL)
            DB::table('report_updates')->delete();
            DB::table('reports')->delete();
        });

        return response()->json(['message' => 'Semua riwayat laporan telah berhasil dibersihkan.']);
    }
}
