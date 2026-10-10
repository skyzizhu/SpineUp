<?php
declare(strict_types=1);

/**
 * 针对运行中的本地 Apache 服务器真实接口全量测试
 */

$baseURL = 'http://127.0.0.1/spineup/v1';

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
        CURLOPT_TIMEOUT        => 5,
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

echo "========================================================\n";
echo "  SpineUp 真实本地服务器接口全链路自动化测试\n";
echo "  目标基地址: {$baseURL}\n";
echo "========================================================\n\n";

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

// 1. GET /v1/config/app
$res1 = sendRequest('GET', "{$baseURL}/config/app");
report("1. GET /v1/config/app 远程配置接口", 
    $res1['code'] === 200 && ($res1['json']['data']['appName'] ?? '') === 'SpineUp',
    "状态码: {$res1['code']}, appName: " . ($res1['json']['data']['appName'] ?? 'null')
);

// 2. POST /v1/auth/guest
$deviceUuid = 'live-test-' . bin2hex(random_bytes(6));
$res2 = sendRequest('POST', "{$baseURL}/auth/guest", [
    'deviceUuid'  => $deviceUuid,
    'deviceModel' => 'iPhone 17 Pro',
    'locale'      => 'zh-Hans',
]);
$jwtToken = $res2['json']['data']['token'] ?? '';
report("2. POST /v1/auth/guest 访客秒开与 JWT 签发",
    $res2['code'] === 200 && !empty($jwtToken),
    "用户ID: " . ($res2['json']['data']['userId'] ?? '') . ", Token 长度: " . strlen($jwtToken)
);

// 3. GET /v1/users/me (带 Bearer Token)
$res3 = sendRequest('GET', "{$baseURL}/users/me", null, $jwtToken);
report("3. GET /v1/users/me 用户个人资料与偏好拉取",
    $res3['code'] === 200 && ($res3['json']['data']['user_uuid'] ?? '') === $deviceUuid,
    "昵称: " . ($res3['json']['data']['nickname'] ?? '')
);

// 4. PUT /v1/users/settings (更新坐姿基准零点与人设)
$res4 = sendRequest('PUT', "{$baseURL}/users/settings", [
    'activePersonaId'       => 'cat',
    'calibrationBasePitch'  => -14.2,
    'calibrationBaseRoll'   => 4.8,
    'slightSlumpThreshold'  => 16.0,
    'severeSlumpThreshold'  => 32.0,
], $jwtToken);
report("4. PUT /v1/users/settings 更新校准零点与人设",
    $res4['code'] === 200 && ($res4['json']['data']['updated'] ?? false) === true
);

// 5. 再次 GET /v1/users/me 验证数据库持久化更新
$res5 = sendRequest('GET', "{$baseURL}/users/me", null, $jwtToken);
$updatedPitch = (float)($res5['json']['data']['calibration_base_pitch'] ?? 0);
$updatedPersona = (string)($res5['json']['data']['active_persona_id'] ?? '');
report("5. 验证更新后的坐姿零点已真实入库",
    abs($updatedPitch - (-14.2)) < 0.01 && $updatedPersona === 'cat',
    "新零点 Pitch: {$updatedPitch}, 宠物人设: {$updatedPersona}"
);

// 6. POST /v1/ai/reminder 针对 4 种角色进行违规拟人提醒测试
$personas = ['worker', 'cat', 'coach', 'anime'];
foreach ($personas as $persona) {
    $resAI = sendRequest('POST', "{$baseURL}/ai/reminder", [
        'persona'     => $persona,
        'angleDeg'    => 28.5,
        'durationSec' => 7.0,
        'state'       => 'severeSlump'
    ]);
    $text = $resAI['json']['reminderText'] ?? '';
    report("6. POST /v1/ai/reminder [{$persona}] 角色提醒生成",
        $resAI['code'] === 200 && !empty($text),
        "\"{$text}\""
    );
}

// 7. 异常测试：测试未授权请求是否正确拦截
$res7 = sendRequest('GET', "{$baseURL}/users/me", null, 'invalid_token');
report("7. 异常拦截测试：非法 Token 应当返回 401 Unauthorized",
    $res7['code'] === 401,
    "HTTP 状态码: {$res7['code']}"
);

// 8. POST /v1/ai/posture-hazard 危害透视
$res8 = sendRequest('POST', "{$baseURL}/ai/posture-hazard", [
    'pitchDeg'         => 28.5,
    'extraLoadKg'      => 22.1,
    'slumpDurationSec' => 1500,
    'violationsCount'  => 12,
    'persona'          => 'worker',
    'userName'         => '测试阿强',
    'locale'           => 'zh-Hans',
]);
report("8. POST /v1/ai/posture-hazard 危害透视接口",
    $res8['code'] === 200 && !empty($res8['json']['data']['metaphor_comparison']),
    "比喻: " . mb_substr($res8['json']['data']['metaphor_comparison'] ?? '', 0, 28) . '...'
);

// 9. POST /v1/ai/relief-prescription 30s 急救处方
$res9 = sendRequest('POST', "{$baseURL}/ai/relief-prescription", [
    'pitchDeg'    => 22.0,
    'extraLoadKg' => 16.5,
    'persona'     => 'worker',
    'locale'      => 'zh-Hans',
]);
report("9. POST /v1/ai/relief-prescription 30秒急救处方接口",
    $res9['code'] === 200 && !empty($res9['json']['data']['action1_tips']),
    "动作指导: " . mb_substr($res9['json']['data']['action1_tips'] ?? '', 0, 28) . '...'
);

// 10. GET /v1/leaderboard 骨气榜
$res10 = sendRequest('GET', "{$baseURL}/leaderboard?type=energy&page=1&page_size=10", null, $jwtToken);
report("10. GET /v1/leaderboard 骨气能量榜检索",
    $res10['code'] === 200 && isset($res10['json']['data']['top_list']),
    "上榜人数: " . count($res10['json']['data']['top_list'] ?? [])
);

// 11. PUT /v1/users/profile 修改昵称
$res11 = sendRequest('PUT', "{$baseURL}/users/profile", [
    'nickname' => '挺拔极客阿强',
], $jwtToken);
report("11. PUT /v1/users/profile 修改个性昵称",
    $res11['code'] === 200 && ($res11['json']['data']['nickname'] ?? '') === '挺拔极客阿强'
);

// 12. POST /v1/relief/claim 30 秒微操打卡
$res12 = sendRequest('POST', "{$baseURL}/relief/claim", [
    'action_type'   => 'CHIN_TUCK',
    'pitch_deg'     => 15.0,
    'extra_load_kg' => 12.0,
    'duration_sec'  => 30,
], $jwtToken);
report("12. POST /v1/relief/claim 30秒微操打卡领能量",
    $res12['code'] === 200 && ($res12['json']['data']['claimed'] ?? false) === true,
    "获得能量币: +" . ($res12['json']['data']['reward_coins'] ?? 0) . ", 最新余额: " . ($res12['json']['data']['current_balance'] ?? 0)
);

echo "\n========================================================\n";
echo "  全量接口测试汇总: 通过 {$pass} 项 / 失败 {$fail} 项\n";
echo "========================================================\n";
exit($fail === 0 ? 0 : 1);
