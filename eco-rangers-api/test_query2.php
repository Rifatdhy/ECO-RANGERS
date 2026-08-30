<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

DB::enableQueryLog();
$t0 = microtime(true);
$q = \App\Models\Report::select(['id', 'user_id', 'judul', 'kategori', 'deskripsi', 'lokasi_text', 'lat', 'lng', 'foto_path', 'status', 'konfirmasi_user', 'created_at'])
    ->with('user:id,name,username')
    ->withCount('votes')
    ->with(['votes' => fn ($v) => $v->where('user_id', 1)->select('id', 'report_id')])
    ->orderByDesc('id')
    ->limit(10);
$sql = $q->toSql();
echo "SQL: $sql\n";
$reports = $q->get();
echo 'get count=' . $reports->count() . ' time=' . round((microtime(true) - $t0) * 1000) . "ms\n";
$log = DB::getQueryLog();
echo 'queries=' . count($log) . "\n";
foreach ($log as $i => $l) {
    echo "$i: " . substr($l['query'], 0, 120) . " (" . round($l['time'], 1) . "ms)\n";
}
