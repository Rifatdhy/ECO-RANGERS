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

        // Normalisasi status ke lowercase + agregasi vote (foto_url dari accessor model).
        $reports->transform(function ($report) use ($user) {
            $report->status = strtolower($report->status);
            $report->kategori = strtolower($report->kategori);
            $report->vote_count = (int) $report->votes_count;
            $report->voted_by_me = $report->votes->isNotEmpty();
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

        $report->loadCount(['votes' => fn ($v) => $v->select('id')]);
        $report->load(['user', 'updates', 'votes' => fn ($v) => $v->where('user_id', $user->id)->select('id', 'report_id')]);
        $report->status = strtolower($report->status);
        $report->vote_count = (int) $report->votes_count;
        $report->voted_by_me = $report->votes->isNotEmpty();
        $report->makeHidden(['votes', 'votes_count']);
        return response()->json($report);
    }

    public function stats(Request $request)
    {
        $user = $request->user();
        $query = Report::query();

        if (!$user->tokenCan('role:admin')) {
            $query->where('user_id', $user->id);
        }

        // Total + per-status dalam satu query (conditional aggregation).
        $counts = (clone $query)
            ->selectRaw(
                'COUNT(*) as total,
                SUM(CASE WHEN status = \'pending\' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = \'diproses\' THEN 1 ELSE 0 END) as diproses,
                SUM(CASE WHEN status = \'selesai\' THEN 1 ELSE 0 END) as selesai,
                SUM(CASE WHEN status = \'ditolak\' THEN 1 ELSE 0 END) as ditolak'
            )
            ->first();

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

        // Rata-rata waktu tanggap (jam): selisih created_at → update pertama,
        // via join subquery teragregasi (satu pass, bukan per-baris).
        // ponytail: varian SQLite (julianday); untuk MySQL pakai TIMESTAMPDIFF(HOUR, ...).
        $avgHours = (clone $query)
            ->joinSub(
                ReportUpdate::selectRaw('report_id, MIN(created_at) as first_at')
                    ->groupBy('report_id'),
                'first_updates',
                'first_updates.report_id',
                '=',
                'reports.id'
            )
            ->selectRaw('AVG(julianday(first_updates.first_at) - julianday(reports.created_at)) * 24 as avg_h')
            ->first()?->avg_h;

        return response()->json([
            'total' => (int) ($counts->total ?? 0),
            'pending' => (int) ($counts->pending ?? 0),
            'diproses' => (int) ($counts->diproses ?? 0),
            'selesai' => (int) ($counts->selesai ?? 0),
            'ditolak' => (int) ($counts->ditolak ?? 0),
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

        // Toggle atomik dalam transaksi: unique(user_id, report_id) menjamin
        // satu baris per pasangan; delete+create tidak mungkin dobel.
        $voted = DB::transaction(function () use ($user, $report) {
            $deleted = Vote::where('user_id', $user->id)->where('report_id', $report->id)->delete();
            if ($deleted) {
                return false;
            }
            Vote::create(['user_id' => $user->id, 'report_id' => $report->id]);
            return true;
        });

        return response()->json([
            'voted' => $voted,
            'votes' => $report->votes()->count(),
        ])->header('Cache-Control', 'no-store');
    }

    public function exportCsvUrl(Request $request)
    {
        // Terbitkan URL unduhan bertanda (HMAC + expires 60 detik) untuk admin.
        // Token API tidak pernah ditaruh di query string.
        $payload = base64_encode(json_encode([
            's' => strtolower($request->input('status', 'semua')),
            'k' => strtolower($request->input('kategori', 'semua')),
            'q' => $request->input('q'),
        ]));
        $exp = now()->addSeconds(60)->getTimestamp();
        $sig = hash_hmac('sha256', $payload . '.' . $exp, config('app.key'));

        $url = url('/api/admin/export/reports')
            . '?p=' . urlencode($payload) . '&e=' . $exp . '&sig=' . $sig;

        return response()->json(['url' => $url])->header('Cache-Control', 'no-store');
    }

    public function exportCsv(Request $request)
    {
        // Hanya URL bertanda yang diizinkan; tanpa token di query string.
        $payload = $request->input('p');
        $exp = (int) $request->input('e', 0);
        $sig = $request->input('sig');
        if (! $payload || ! $exp || ! $sig || now()->getTimestamp() > $exp) {
            abort(403, 'Link kedaluwarsa');
        }
        if (! hash_equals(hash_hmac('sha256', $payload . '.' . $exp, config('app.key')), $sig)) {
            abort(403, 'Signature tidak valid');
        }
        $filters = json_decode(base64_decode($payload), true) ?? [];

        $query = Report::with('user:id,name,username')
            ->orderByDesc('id');

        if (($filters['s'] ?? 'semua') !== 'semua') {
            $query->where('status', $filters['s']);
        }
        if (($filters['k'] ?? 'semua') !== 'semua') {
            $query->where('kategori', $filters['k']);
        }
        if (! empty($filters['q'])) {
            $q = $this->sanitizeSearch($filters['q']);
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
