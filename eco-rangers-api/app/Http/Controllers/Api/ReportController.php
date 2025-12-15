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
        $query = Report::with(['user', 'updates'])->orderByDesc('id');

        if ($user) { // <-- PERUBAHAN DI SINI
            if ($user->tokenCan('role:admin')) {
                // Admin melihat semua laporan (tidak ada filter tambahan)
            } else {
                // Pengguna biasa hanya melihat laporan mereka sendiri
                $query->where('user_id', $user->id);
            }
        } else {
            // Jika tidak ada user (tamu), jangan tampilkan laporan sama sekali.
            return response()->json([]); // <-- PERUBAHAN DI SINI
        }

        $reports = $query->get();

        $reports->each(function ($report) {
            $report->foto_url = $report->foto_path ? asset('storage/' . $report->foto_path) : null;
            $report->updates->each(function ($update) {
                $update->foto_dokumentasi_url = $update->foto_dokumentasi ? asset('storage/' . $update->foto_dokumentasi) : null;
            });
            $report->status = ucfirst($report->status);
        });

        return response()->json($reports);
    }

    public function show(Report $report, Request $request)
    {
        $user = $request->user();

        if ($user && !$user->tokenCan('role:admin') && $report->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $report->load(['user', 'updates']);
        $report->status = ucfirst($report->status);
        return response()->json($report);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'judul'       => ['required','string','max:255'],
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
            'deskripsi'   => $validated['deskripsi'],
            'lokasi_text' => $validated['lokasi_text'] ?? null,
            'lat'         => $validated['lat'] ?? null,
            'lng'         => $validated['lng'] ?? null,
            'foto_path'   => $path,
            'status'      => 'pending',
        ]);

        $report->load('user');
        $report->status = ucfirst($report->status);

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
            $path = $request->file('foto_dokumentasi')->store('documentation', 'public');
        }

        DB::transaction(function () use ($report, $validated, $path) {
            $report->updates()->create([
                'status'           => $validated['status'],
                'keterangan'       => $validated['keterangan'] ?? null,
                'nama_petugas'     => $validated['nama_petugas'] ?? null,
                'foto_dokumentasi' => $path,
            ]);

            $report->status = $validated['status'];
            $report->save();
        });

        $report->load(['user', 'updates']);
        $report->status = ucfirst($report->status);

        return response()->json([
            'message' => 'Status laporan berhasil diubah',
            'report' => $report
        ]);
    }

    public function destroy(Report $report)
    {
        if ($report->foto_path) {
            Storage::disk('public')->delete($report->foto_path);
        }

        foreach ($report->updates as $update) {
            if ($update->foto_dokumentasi) {
                Storage::disk('public')->delete($update->foto_dokumentasi);
            }
        }

        $report->delete();
        return response()->json(['message' => 'Laporan berhasil dihapus', 'deleted' => true]);
    }

    public function clearAll(Request $request)
    {
        if (!$request->user() || !$request->user()->tokenCan('role:admin')) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

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
