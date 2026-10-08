<?php
declare(strict_types=1);

/**
 * SpineUp 后端接口自动化测试与验证脚本
 * 可通过 PHP CLI 直接运行: php backend/test_api.php
 */

require_once __DIR__ . '/autoload.php';

use App\Common\Database;
use App\Common\JWT;
use App\Services\AIService;
use App\Controllers\AIController;

echo "========================================================\n";
echo "   SpineUp (Apache + MySQL + PHP) 接口测试与自检\n";
echo "========================================================\n\n";

$passCount = 0;
$failCount = 0;

function assertTest(string $desc, bool $condition): void {
    global $passCount, $failCount;
    if ($condition) {
        echo "  [PASS] {$desc}\n";
        $passCount++;
    } else {
        echo "  [FAIL] {$desc}\n";
        $failCount++;
    }
}

// 1. 测试数据库连通与表初始化
echo "1. 数据库与持久化测试...\n";
try {
    $db = Database::getInstance();
    $stmt = $db->query("SELECT COUNT(*) as cnt FROM su_users");
    $row = $stmt->fetch();
    assertTest("数据库成功初始化并可执行查询 (当前用户数: {$row['cnt']})", true);
} catch (Exception $e) {
    assertTest("数据库连接异常: " . $e->getMessage(), false);
}

// 2. 测试 JWT 签发与验签
echo "\n2. JWT 安全签名与防篡改测试...\n";
$config = require __DIR__ . '/config/app.php';
$payload = ['uid' => 1001, 'uuid' => 'test-device-uuid', 'isGuest' => true];
$token = JWT::encode($payload, $config['jwt_secret']);
$decoded = JWT::decode($token, $config['jwt_secret']);
assertTest("JWT 正常签发且可解密恢复", $decoded !== null && $decoded['uid'] === 1001);

$tamperedToken = $token . 'bad';
$tamperedDecoded = JWT::decode($tamperedToken, $config['jwt_secret']);
assertTest("篡改后的 JWT 验签失败被拦截", $tamperedDecoded === null);

// 3. 测试 AI 提醒引擎与 4 角色人设语料
echo "\n3. AI 网关与拟人化宠物违规提醒测试 (/v1/ai/reminder)...\n";
$aiService = new AIService();
$personas = ['worker', 'cat', 'coach', 'anime'];

foreach ($personas as $persona) {
    $startTime = microtime(true);
    $text = $aiService->generateReminder($persona, 26.5, 8.0, 'severeSlump');
    $elapsedMs = round((microtime(true) - $startTime) * 1000, 2);
    
    assertTest(
        "角色 [{$persona}] 违规提醒生成成功 (耗时: {$elapsedMs}ms): \"{$text}\"",
        !empty($text) && is_string($text)
    );
}

// 4. 测试缓存命中速度
echo "\n4. 特征哈希语义缓存性能测试...\n";
$startTime = microtime(true);
$cachedText = $aiService->generateReminder('worker', 26.5, 8.0, 'severeSlump');
$cacheMs = round((microtime(true) - $startTime) * 1000, 2);
assertTest("缓存命中响应速度 < 10ms (实际: {$cacheMs}ms): \"{$cachedText}\"", $cacheMs < 10.0);

// 5. 模拟访客注册与用户设置
echo "\n5. 访客账户入库与设置更新测试...\n";
$testUuid = 'unit-test-' . bin2hex(random_bytes(4));
$stmt = $db->prepare("INSERT INTO su_users (user_uuid, is_guest, nickname) VALUES (?, 1, '测试小助手')");
$stmt->execute([$testUuid]);
$userId = (int)$db->lastInsertId();

$stmtSet = $db->prepare("INSERT INTO su_user_settings (user_id, calibration_base_pitch, calibration_base_roll) VALUES (?, -12.5, 3.2)");
$stmtSet->execute([$userId]);

$query = $db->prepare("SELECT s.calibration_base_pitch, s.calibration_base_roll FROM su_user_settings s WHERE s.user_id = ?");
$query->execute([$userId]);
$settings = $query->fetch();

assertTest("坐姿基准零点正确入库 (Pitch: {$settings['calibration_base_pitch']}, Roll: {$settings['calibration_base_roll']})", 
    abs($settings['calibration_base_pitch'] - (-12.5)) < 0.001
);

echo "\n========================================================\n";
echo "   测试汇总: 通过 {$passCount} 项 / 失败 {$failCount} 项\n";
echo "========================================================\n";

if ($failCount === 0) {
    echo "🎉 全部后端核心模块验证通过！\n\n";
    exit(0);
} else {
    echo "❌ 存在未通过项，请检查日志。\n\n";
    exit(1);
}
