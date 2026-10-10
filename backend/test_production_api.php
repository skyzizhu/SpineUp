<?php
declare(strict_types=1);

/**
 * SpineUp 线上服务器 (https://www.yourtools.xyz/spineup) 全量接口自动化测试套件
 */

$baseURL = 'https://www.yourtools.xyz/spineup/v1';

function sendRequest(string $method, string $url, $body = null, $token = null): array {
    $ch = curl_init($url);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) {
        $headers[] = "Authorization: Bearer {$token}";
    }

    $options = [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
    ];
    if ($body !== null) {
        $options[CURLOPT_POSTFIELDS] = json_encode($body);
    }
    curl_setopt_array($ch, $options);

    $raw = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    return [
        'code'    => $httpCode,
        'raw'     => $raw,
        'json'    => json_decode($raw ?: '', true),
        'error'   => $error,
    ];
}

echo "======================================================================\n";
echo "  SpineUp 线上服务器 (https://www.yourtools.xyz/spineup) 全量接口测试\n";
echo "  测试目标基地址: {$baseURL}\n";
echo "======================================================================\n\n";

$pass = 0;
$fail = 0;

function report(string $name, bool $ok, string $extra = '') {
    global $pass, $fail;
    if ($ok) {
        echo "  [PASS] {$name}" . ($extra ? " -> {$extra}" : "") . "\n";
        $pass++;
    } else {
        echo "  [FAIL] {$name}" . ($extra ? " -> {$extra}" : "") . "\n";
        $fail++;
    }
}

// -------------------------------------------------------------
// 1. GET /v1/config/app 远程配置中心
// -------------------------------------------------------------
$res1 = sendRequest('GET', "{$baseURL}/config/app");
report("1. GET /v1/config/app (远程配置中心)", 
    $res1['code'] === 200 && ($res1['json']['data']['appName'] ?? '') === 'SpineUp',
    "HTTP {$res1['code']}, appName=" . ($res1['json']['data']['appName'] ?? 'null')
);

// -------------------------------------------------------------
// 2. POST /v1/auth/guest 访客秒开与 JWT 签发
// -------------------------------------------------------------
$deviceUuid = 'prod-test-' . bin2hex(random_bytes(6));
$res2 = sendRequest('POST', "{$baseURL}/auth/guest", [
    'deviceUuid'  => $deviceUuid,
    'deviceModel' => 'iPhone 17 Pro',
    'locale'      => 'zh-Hans',
]);
$jwtToken = $res2['json']['data']['token'] ?? '';
$userId = $res2['json']['data']['userId'] ?? 0;
report("2. POST /v1/auth/guest (访客秒开与签发 JWT)",
    $res2['code'] === 200 && !empty($jwtToken) && $userId > 0,
    "HTTP {$res2['code']}, UID={$userId}, TokenLen=" . strlen($jwtToken)
);

// -------------------------------------------------------------
// 3. GET /v1/users/me 用户个人资料与偏好
// -------------------------------------------------------------
$res3 = sendRequest('GET', "{$baseURL}/users/me", null, $jwtToken);
report("3. GET /v1/users/me (用户个人资料与偏好)",
    $res3['code'] === 200 && ($res3['json']['data']['user_uuid'] ?? '') === $deviceUuid,
    "HTTP {$res3['code']}, 昵称: " . ($res3['json']['data']['nickname'] ?? '')
);

// -------------------------------------------------------------
// 4. PUT /v1/users/settings 更新坐姿基准零点与人设
// -------------------------------------------------------------
$res4 = sendRequest('PUT', "{$baseURL}/users/settings", [
    'activePersonaId'       => 'cat',
    'calibrationBasePitch'  => -14.2,
    'calibrationBaseRoll'   => 4.8,
    'slightSlumpThreshold'  => 16.0,
    'severeSlumpThreshold'  => 32.0,
], $jwtToken);
report("4. PUT /v1/users/settings (更新坐姿基准与人设)",
    $res4['code'] === 200 && ($res4['json']['data']['updated'] ?? false) === true,
    "HTTP {$res4['code']}"
);

// -------------------------------------------------------------
// 5. 再次 GET /v1/users/me 验证数据库持久化更新
// -------------------------------------------------------------
$res5 = sendRequest('GET', "{$baseURL}/users/me", null, $jwtToken);
$updatedPitch = (float)($res5['json']['data']['calibration_base_pitch'] ?? 0);
$updatedPersona = (string)($res5['json']['data']['active_persona_id'] ?? '');
report("5. 验证更新基准已真实入库",
    abs($updatedPitch - (-14.2)) < 0.01 && $updatedPersona === 'cat',
    "新基准 Pitch: {$updatedPitch}, 人设: {$updatedPersona}"
);

// -------------------------------------------------------------
// 6. PUT /v1/users/profile 修改个性昵称
// -------------------------------------------------------------
$newNickname = '挺拔先锋-' . rand(100, 999);
$res6 = sendRequest('PUT', "{$baseURL}/users/profile", [
    'nickname' => $newNickname,
], $jwtToken);
report("6. PUT /v1/users/profile (修改个性昵称)",
    $res6['code'] === 200 && ($res6['json']['data']['nickname'] ?? '') === $newNickname,
    "新昵称: {$newNickname}"
);

// -------------------------------------------------------------
// 7. POST /v1/ai/reminder AI 角色提醒生成
// -------------------------------------------------------------
$personas = ['worker', 'cat', 'coach'];
foreach ($personas as $persona) {
    $resAI = sendRequest('POST', "{$baseURL}/ai/reminder", [
        'persona'     => $persona,
        'angleDeg'    => 28.5,
        'durationSec' => 7.0,
        'state'       => 'severeSlump'
    ]);
    $text = $resAI['json']['reminderText'] ?? '';
    report("7. POST /v1/ai/reminder [{$persona}] AI提醒生成",
        $resAI['code'] === 200 && !empty($text),
        "\"{$text}\""
    );
}

// -------------------------------------------------------------
// 8. POST /v1/ai/posture-hazard 危害透视
// -------------------------------------------------------------
$res8 = sendRequest('POST', "{$baseURL}/ai/posture-hazard", [
    'pitchDeg'         => 28.5,
    'extraLoadKg'      => 22.1,
    'slumpDurationSec' => 1500,
    'violationsCount'  => 12,
    'persona'          => 'worker',
    'userName'         => '测试极客',
    'locale'           => 'zh-Hans',
]);
$metaphor = $res8['json']['data']['metaphor_comparison'] ?? '';
report("8. POST /v1/ai/posture-hazard (危害透视分析)",
    $res8['code'] === 200 && !empty($metaphor),
    "比喻: " . mb_substr($metaphor, 0, 24) . "..."
);

// -------------------------------------------------------------
// 9. POST /v1/ai/relief-prescription 30s 急救处方
// -------------------------------------------------------------
$res9 = sendRequest('POST', "{$baseURL}/ai/relief-prescription", [
    'pitchDeg'    => 22.0,
    'extraLoadKg' => 16.5,
    'persona'     => 'worker',
    'locale'      => 'zh-Hans',
]);
$tips = $res9['json']['data']['action1_tips'] ?? '';
report("9. POST /v1/ai/relief-prescription (30秒急救微操处方)",
    $res9['code'] === 200 && !empty($tips),
    "动作指导: " . mb_substr($tips, 0, 24) . "..."
);

// -------------------------------------------------------------
// 10. GET /v1/leaderboard 骨气榜
// -------------------------------------------------------------
$res10 = sendRequest('GET', "{$baseURL}/leaderboard?type=energy&page=1&page_size=10", null, $jwtToken);
$list = $res10['json']['data']['top_list'] ?? [];
report("10. GET /v1/leaderboard (骨气能量榜检索)",
    $res10['code'] === 200 && is_array($list),
    "榜单人数: " . count($list) . ", 我的名次: " . ($res10['json']['data']['my_rank']['rank'] ?? 'null')
);

// -------------------------------------------------------------
// 11. POST /v1/relief/claim 30 秒微操打卡领能量
// -------------------------------------------------------------
$res11 = sendRequest('POST', "{$baseURL}/relief/claim", [
    'action_type'   => 'CHIN_TUCK',
    'pitch_deg'     => 15.0,
    'extra_load_kg' => 12.0,
    'duration_sec'  => 30,
], $jwtToken);
report("11. POST /v1/relief/claim (30秒微操打卡领能量)",
    $res11['code'] === 200 && ($res11['json']['data']['claimed'] ?? false) === true,
    "获得能量币: +" . ($res11['json']['data']['reward_coins'] ?? 0) . ", 余额: " . ($res11['json']['data']['current_balance'] ?? 0)
);

// -------------------------------------------------------------
// 12. POST /v1/sessions/sync 姿态会话同步
// -------------------------------------------------------------
$sessionDate = date('Y-m-d');
$res12 = sendRequest('POST', "{$baseURL}/sessions/sync", [
    'sessionDate'        => $sessionDate,
    'uprightDurationSec' => 1800.0,
    'slumpDurationSec'   => 300.0,
    'violationsCount'    => 5,
    'avgPitchDeg'        => 8.2,
    'maxPitchDeg'        => 26.5,
    'earnedCoins'        => 30,
], $jwtToken);
report("12. POST /v1/sessions/sync (姿态监测会话数据同步)",
    $res12['code'] === 200 && ($res12['json']['data']['synced'] ?? false) === true,
    "HTTP {$res12['code']}, SessionDate: {$sessionDate}"
);

// -------------------------------------------------------------
// 13. GET /v1/sessions/history 历史会话拉取
// -------------------------------------------------------------
$res13 = sendRequest('GET', "{$baseURL}/sessions/history?days=7", null, $jwtToken);
$history = $res13['json']['data']['sessions'] ?? [];
report("13. GET /v1/sessions/history (历史监测会话拉取)",
    $res13['code'] === 200 && is_array($history),
    "会话条数: " . count($history)
);

// -------------------------------------------------------------
// 14. POST /v1/reports/daily 保存每日体态报告
// -------------------------------------------------------------
$res14 = sendRequest('POST', "{$baseURL}/reports/daily", [
    'report_date'          => $sessionDate,
    'persona_id'           => 'worker',
    'diagnosis_title'      => '阶段性伏案打工低头综合征',
    'doctor_prescription'  => '建议每工作 45 分钟进行一次 30 秒麦肯基收下巴微操。',
    'persona_comment'      => '今日挺拔表现可圈可点，继续保持！',
    'equivalent_item_name' => '一只成年金毛寻回犬',
    'equivalent_item_kg'   => 18.5,
], $jwtToken);
report("14. POST /v1/reports/daily (保存每日体态健康报告)",
    $res14['code'] === 200 && ($res14['json']['data']['report_id'] ?? 0) > 0,
    "HTTP {$res14['code']}, ReportID: " . ($res14['json']['data']['report_id'] ?? 0)
);

// -------------------------------------------------------------
// 15. GET /v1/reports/daily 获取今日体态报告
// -------------------------------------------------------------
$res15 = sendRequest('GET', "{$baseURL}/reports/daily?date={$sessionDate}", null, $jwtToken);
report("15. GET /v1/reports/daily (拉取每日体态报告)",
    $res15['code'] === 200 && !empty($res15['json']['data']['diagnosis_title']),
    "诊断: " . ($res15['json']['data']['diagnosis_title'] ?? '')
);

// -------------------------------------------------------------
// 16. GET /v1/reports/periodic 获取周期性周报
// -------------------------------------------------------------
$res16 = sendRequest('GET', "{$baseURL}/reports/periodic?period_type=weekly", null, $jwtToken);
$shareHash = $res16['json']['data']['share_hash'] ?? '';
report("16. GET /v1/reports/periodic (生成多维度周期性周报)",
    $res16['code'] === 200 && !empty($shareHash),
    "周报得分: " . ($res16['json']['data']['health_score'] ?? '') . ", 分享哈希: {$shareHash}"
);

// -------------------------------------------------------------
// 17. GET /v1/reports/share 免鉴权公开分享链接查询
// -------------------------------------------------------------
if (!empty($shareHash)) {
    $res17 = sendRequest('GET', "{$baseURL}/reports/share?hash={$shareHash}");
    report("17. GET /v1/reports/share (免鉴权公开分享卡片查询)",
        $res17['code'] === 200 && ($res17['json']['data']['share_hash'] ?? '') === $shareHash,
        "分享人: " . ($res17['json']['data']['nickname'] ?? '')
    );
} else {
    report("17. GET /v1/reports/share", false, "未获取到有效分享哈希");
}

// -------------------------------------------------------------
// 18. POST /v1/logs/client 客户端硬件与异常埋点上报
// -------------------------------------------------------------
$res18 = sendRequest('POST', "{$baseURL}/logs/client", [
    'category'  => 'Motion',
    'level'     => 'INFO',
    'message'   => 'AirPods Pro connected and streaming at 60Hz',
    'context'   => ['firmware' => '6A326', 'device' => 'iPhone17,1']
]);
report("18. POST /v1/logs/client (客户端硬件与异常埋点上报)",
    $res18['code'] === 200 && ($res18['json']['data']['count'] ?? 0) >= 1,
    "已写入日志数量: " . ($res18['json']['data']['count'] ?? 0)
);

// -------------------------------------------------------------
// 19. 异常测试：非法 Token 拦截 (401 Unauthorized)
// -------------------------------------------------------------
$res19 = sendRequest('GET', "{$baseURL}/users/me", null, 'illegal_jwt_token_string');
report("19. 安全拦截测试 (非法 Token 应返回 401)",
    $res19['code'] === 401,
    "HTTP {$res19['code']}"
);

// -------------------------------------------------------------
// 20. 异常测试：不存在路由 404 Not Found
// -------------------------------------------------------------
$res20 = sendRequest('GET', "{$baseURL}/non_existent_route");
report("20. 404 路由测试 (无效路径应返回 404)",
    $res20['code'] === 404,
    "HTTP {$res20['code']}"
);

echo "\n======================================================================\n";
echo "  测试结果: 通过 {$pass} 项 / 失败 {$fail} 项\n";
echo "======================================================================\n";
exit($fail === 0 ? 0 : 1);
