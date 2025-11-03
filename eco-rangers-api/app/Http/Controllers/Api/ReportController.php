<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Report;

class ReportController extends Controller
{
    /**
     * GET /api/reports
     * Tampilkan semua laporan
     */
    public function index()
    {
        // PERBAIKAN: Mengirim 'judul' dan 'deskripsi' agar sesuai dengan Flutter
        $data = Report::orderByDesc('id')->get()->map(function ($r) {
            return [
                'id' => $r->id,
                'judul' => $r->judul,
                'deskripsi' => $r->deskripsi,
                'lokasi_text' => $r->lokasi_text,
                'lat' => $r->lat,
                'lng' => $r->lng,
                'status' => $r->status,
                'foto_url' => $r->foto_path ? asset('storage/'.$r->foto_path) : null,
                'created_at' => $r->created_at,
            ];
        });

        return response()->json($data);
    }

    /**
     * GET /api/reports/{report}
     * Detail laporan tunggal
     */
    public function show(Report $report)
    {
        $report->foto_url = $report->foto_path ? asset('storage/'.$report->foto_path) : null;
        return response()->json($report);
    }

    /**
     * POST /api/reports
     * Buat laporan baru
     */
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

        $path = $request->hasFile('foto')
            ? $request->file('foto')->store('reports', 'public')
            : null;

        $report = Report::create([
            'judul'       => $validated['judul'],
            'deskripsi'   => $validated['deskripsi'],
            'lokasi_text' => $validated['lokasi_text'] ?? null,
            'lat'         => $validated['lat'] ?? null,
            'lng'         => $validated['lng'] ?? null,
            'foto_path'   => $path,
            'status'      => 'pending',
        ]);

        $report->foto_url = $path ? asset('storage/'.$path) : null;

        return response()->json(['report' => $report], 201);
    }

    /**
     * PATCH /api/reports/{report}/status
     * Update status laporan
     */
    public function updateStatus(Request $request, Report $report)
    {
        $request->validate([
            // Menambahkan 'ditolak' sebagai status yang valid
            'status' => ['required','in:pending,diproses,selesai,ditolak'],
        ]);

        $report->status = $request->input('status');
        $report->save();

        $report->foto_url = $report->foto_path ? asset('storage/'.$report->foto_path) : null;

        return response()->json(['report' => $report]);
    }

    /**
     * DELETE /api/reports/{report}
     * Hapus laporan
     */
    public function destroy(Report $report)
    {
        if ($report->foto_path) {
            Storage::disk('public')->delete($report->foto_path);
        }

        $report->delete();

        return response()->json(['deleted' => true]);
    }
}
