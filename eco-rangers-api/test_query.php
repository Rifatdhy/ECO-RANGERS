<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$t0 = microtime(true);
$count = \App\Models\Report::with('user:id,name,username')
    ->withCount('votes')
    ->with(['votes' => fn ($v) => $v->where('user_id', 1)->select('id', 'report_id')])
    ->orderByDesc('id')
    ->limit(5)
    ->get()
    ->count();
echo 'count=' . $count . ' time=' . round((microtime(true) - $t0) * 1000) . "ms\n";
