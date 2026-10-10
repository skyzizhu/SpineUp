<?php
declare(strict_types=1);

require_once __DIR__ . '/autoload.php';

/**
 * 全周期报告 API 真实服务联调测试脚本
 */

$baseUrl = 'http://127.0.0.1/spineup/v1';

// 1. 获取 Guest Token
$ch = curl_init("{$baseUrl}/auth/guest");
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode(['device_uuid' => 'TEST_UUID_PERIODIC']),
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
]);
$res = curl_exec($ch);
curl_close($ch);
$authData = json_decode($res, true);
$token = $authData['data']['token'] ?? '';
echo "1. 认证状态: " . ($token ? "成功 (UID: {$authData['data']['user']['id']})" : "失败") . "\n";

// 2. 测试获取周报 GET /v1/reports/periodic?period_type=weekly
$ch = curl_init("{$baseUrl}/reports/periodic?period_type=weekly");
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => [
        'Content-Type: application/json',
        "Authorization: Bearer {$token}",
    ],
]);
$reportRes = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
$reportData = json_decode($reportRes, true);

echo "2. 周报获取 (HTTP {$httpCode}): " . ($reportData['code'] === 200 ? "PASS" : "FAIL") . "\n";
if (isset($reportData['data'])) {
    $d = $reportData['data'];
    echo "   - 周期标识: {$d['period_key']} ({$d['date_range_text']})\n";
    echo "   - 健康评分: {$d['health_score']} 分 | 挺拔率: {$d['upright_percentage']}%\n";
    echo "   - 总监测时长: {$d['total_wear_hours']} 小时 | 协助减负: {$d['alleviated_load_kg']} kg\n";
    echo "   - 最佳挺拔日: {$d['best_day_name']} | 富贵包风险: {$d['dowager_hump_risk']}%\n";
    echo "   - 生活化比喻: {$d['equivalent_item_name']}\n";
    echo "   - AI 伴侣周度复盘: {$d['ai_persona_summary']}\n";
    echo "   - 7 天柱状细分数据项: " . count($d['daily_breakdown']) . " 天\n";
    echo "   - 分享短链哈希: {$d['share_hash']}\n";

    // 3. 测试公开分享链接免鉴权查看
    $shareHash = $d['share_hash'];
    $ch = curl_init("{$baseUrl}/reports/share?hash={$shareHash}");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $shareRes = curl_exec($ch);
    $shareCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    echo "3. 免鉴权公开分享查询 (HTTP {$shareCode}): " . ($shareCode === 200 ? "PASS" : "FAIL") . "\n";
}

// 4. 测试会话历史接口 GET /v1/sessions/history?days=7
$ch = curl_init("{$baseUrl}/sessions/history?days=7");
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => [
        'Content-Type: application/json',
        "Authorization: Bearer {$token}",
    ],
]);
$histRes = curl_exec($ch);
$histCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
$histData = json_decode($histRes, true);
echo "4. 会话历史查询 (HTTP {$histCode}): " . ($histData['code'] === 200 ? "PASS" : "FAIL") . "\n";
echo "   - 记录数量: " . count($histData['data'] ?? []) . " 条\n";
