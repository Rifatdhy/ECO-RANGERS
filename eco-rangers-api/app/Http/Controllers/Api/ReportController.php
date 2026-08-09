<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Report;
use App\Models\ReportUpdate;
use App\Models\Vote;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Report::select([
                'id', 'user_id', 'judul', 'kategori', 'deskripsi', 'lokasi_text',
                'lat', 'lng', 'foto_path', 'status', 'konfirmasi_user', 'created_at'
            ])
            ->with('user:id,name,username')
            ->withCount('votes')
            ->with(['votes' => fn ($v) => $v->where('user_id', $user->id)->select('id', 'report_id')])
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
            $q = $this->sanitizeSearch($request->input('q'));
            if ($q === null) {
                // ponytail: tolak query <3 karakter agar tidak memicu full scan LIKE.
                $query->whereRaw('1 = 0');
            } else {
                $query->where(function ($sub) use ($q) {
                    $sub->where('judul', 'like', "%{$q}%")
                        ->orWhere('deskripsi', 'like', "%{$q}%")
                        ->orWhere('lokasi_text', 'like', "%{$q}%");
                });
            }
        }

        // Admin dapat melihat semua laporan; pengguna biasa hanya miliknya.
        if (!$user->tokenCan('role:admin')) {
            $query->where('user_id', $user->id);
        }

        $reports = $query
            ->offset(min(max($request->integer('offset', 0), 0), 100000))
            ->limit(min(max($request->integer('limit', 200), 1), 500))
            ->get();

        // Normalisasi status ke lowercase + foto_url konsisten (tanpa nested updates).
        $reports->transform(function ($report) use ($user) {
            $report->status = strtolower($report->status);
            $report->kategori = strtolower($report->kategori);
            $report->vote_count = (int) $report->votes_count;
            $report->voted_by_me = $report->votes->isNotEmpty();
            $report->foto_url = $report->foto_path ? asset('storage/' . $report->foto_path) : null;
            $report->makeHidden(['votes', 'votes_count']);
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
        $report->vote_count = $report->votes()->count();
        $report->voted_by_me = $report->votes()->where('user_id', $user->id)->exists();
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
        // ponytail: varian SQLite (julianday); untuk MySQL pakai TIMESTAMPDIFF(HOUR, ...)
        // dan pertimbangkan agregasi engine bila sudah 100k+ baris.
        $avgHours = (clone $query)
            ->whereHas('updates')
            ->selectRaw('AVG(julianday((SELECT MIN(created_at) FROM report_updates u WHERE u.report_id = reports.id)) - julianday(reports.created_at)) * 24 as avg_h')
            ->first()?->avg_h;

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

    public function confirmResolution(Request $request, Report $report)
    {
        $user = $request->user();

        // Hanya pelapor yang bisa mengonfirmasi penyelesaian.
        if ($report->user_id !== $user->id) {
            abort(403, 'Hanya pelapor yang dapat mengonfirmasi');
        }

        // Konfirmasi hanya valid bila laporan sudah berstatus selesai.
        if ($report->status !== 'selesai') {
            abort(422, 'Laporan belum selesai');
        }

        $validated = $request->validate([
            'konfirmasi' => ['required', 'in:sesuai,tidak_tuntas'],
        ]);

        $report->konfirmasi_user = $validated['konfirmasi'];
        $report->save();

        return response()->json([
            'message' => 'Konfirmasi tersimpan',
            'konfirmasi_user' => $report->konfirmasi_user,
        ])->header('Cache-Control', 'no-store');
    }

    public function toggleVote(Request $request, Report $report)
    {
        $user = $request->user();

        // Cegah IDOR: non-admin hanya boleh vote laporan miliknya sendiri.
        if (! $user->tokenCan('role:admin') && $report->user_id !== $user->id) {
            abort(403, 'Tidak dapat memberikan vote');
        }

        // Toggle atomik (exists -> delete/create) tanpa find-then-create.
        $exists = Vote::where('user_id', $user->id)->where('report_id', $report->id)->exists();
        if ($exists) {
            Vote::where('user_id', $user->id)->where('report_id', $report->id)->delete();
        } else {
            Vote::create(['user_id' => $user->id, 'report_id' => $report->id]);
        }

        return response()->json([
            'voted' => ! $exists,
            'votes' => $report->votes()->count(),
        ])->header('Cache-Control', 'no-store');
    }

    public function exportCsv(Request $request)
    {
        // Route TANPA middleware auth: izinkan token via query (?token=) agar bisa
        // dibuka dari url_launcher (unduhan browser), ATAU via Authorization: Bearer.
        // JANGAN tiru pola token-di-URL pada endpoint lain.
        $user = $request->user();
        $isAdmin = $user && $user->tokenCan('role:admin');
        if (! $isAdmin && $request->bearerToken()) {
            $bearerTok = \Laravel\Sanctum\PersonalAccessToken::findToken($request->bearerToken());
            $isAdmin = $bearerTok
                && $bearerTok->tokenable
                && collect($bearerTok->abilities ?? [])->contains('role:admin');
        }
        if (! $isAdmin && $request->filled('token')) {
            // Menerima plainTextToken penuh ("id|hash") atau hash saja.
            $tok = \Laravel\Sanctum\PersonalAccessToken::findToken($request->input('token'))
                ?? \Laravel\Sanctum\PersonalAccessToken::findToken(explode('|', $request->input('token'), 2)[1] ?? '');
            $isAdmin = $tok
                && $tok->tokenable
                && collect($tok->abilities ?? [])->contains('role:admin');
        }
        if (! $isAdmin) {
            abort(403);
        }

        $query = Report::with('user:id,name,username')
            ->orderByDesc('id');

        if ($request->filled('status')) {
            $query->where('status', strtolower($request->input('status')));
        }
        if ($request->filled('kategori')) {
            $query->where('kategori', strtolower($request->input('kategori')));
        }
        if ($request->filled('q')) {
            $q = $this->sanitizeSearch($request->input('q'));
            if ($q === null) {
                $query->whereRaw('1 = 0');
            } else {
                $query->where(fn ($sub) => $sub
                    ->where('judul', 'like', "%{$q}%")
                    ->orWhere('deskripsi', 'like', "%{$q}%")
                    ->orWhere('lokasi_text', 'like', "%{$q}%"));
            }
        }

        $cols = [
            'id' => 'ID',
            'judul' => 'Judul',
            'kategori' => 'Kategori',
            'status' => 'Status',
            'lokasi_text' => 'Lokasi',
            'lat' => 'Lat',
            'lng' => 'Lng',
            'created_at' => 'Dibuat',
            'user.name' => 'Pelapor',
        ];

        $filename = 'laporan-' . now()->format('Ymd-His') . '.csv';

        return response()->streamDownload(function () use ($query, $cols) {
            $out = fopen('php://output', 'w');
            fwrite($out, "\xEF\xBB\xBF"); // BOM UTF-8 supaya Excel membaca encoding dengan benar.
            fputcsv($out, array_values($cols));
            $query->chunk(500, function ($reports) use ($out, $cols) {
                foreach ($reports as $r) {
                    $row = [];
                    foreach ($cols as $key => $_) {
                        $val = data_get($r, $key);
                        if ($key === 'created_at' && $val) {
                            $val = \Illuminate\Support\Carbon::parse($val)->format('Y-m-d H:i');
                        }
                        $row[] = is_null($val) ? '' : $this->sanitizeCsvCell((string) $val);
                    }
                    fputcsv($out, $row);
                }
            });
            fclose($out);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Cache-Control' => 'private, no-store, no-cache, must-revalidate',
        ]);
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
            if ($validated['status'] !== 'selesai') {
                // Keluar dari status selesai -> konfirmasi pelapor tidak lagi relevan.
                $report->konfirmasi_user = null;
            }
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

    private function sanitizeSearch(string $raw): ?string
    {
        // Escaping wildcard LIKE ('%'/'_') agar input user tidak jadi wildcard.
        $q = trim($raw);
        if (strlen($q) < 3) {
            return null;
        }
        return str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $q);
    }

    private function sanitizeCsvCell(string $value): string
    {
        // Cegah CSV formula injection: sel diawali '=','+','-','@' diberi awalan petik.
        return preg_match('/^[=+\-@]/', $value) ? "'" . $value : $value;
    }
}
