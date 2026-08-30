<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$t0 = microtime(true);
$q = \App\Models\Report::select(['id', 'user_id', 'judul', 'kategori', 'deskripsi', 'lokasi_text', 'lat', 'lng', 'foto_path', 'status', 'konfirmasi_user', 'created_at'])
    ->with('user:id,name,username')
    ->withCount('votes')
    ->with(['votes' => fn ($v) => $v->where('user_id', 1)->select('id', 'report_id')])
    ->orderByDesc('id')
    ->limit(200);
$reports = $q->get();
$t1 = microtime(true);
echo 'get count=' . $reports->count() . ' time=' . round(($t1 - $t0) * 1000) . "ms\n";

$reports->transform(function ($report) {
    $report->status = strtolower($report->status);
    $report->kategori = strtolower($report->kategori);
    $report->vote_count = (int) $report->votes_count;
    $report->voted_by_me = $report->votes->isNotEmpty();
    $report->makeHidden(['votes', 'votes_count']);
    return $report;
});
$t2 = microtime(true);
echo 'transform time=' . round(($t2 - $t1) * 1000) . "ms\n";

$json = $reports->toJson();
$t3 = microtime(true);
echo 'toJson len=' . strlen($json) . ' time=' . round(($t3 - $t2) * 1000) . "ms\n";
