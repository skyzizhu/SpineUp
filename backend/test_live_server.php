<?php
declare(strict_types=1);

/**
 * 针对运行中的本地 Apache 服务器真实接口全量测试
 */

$baseURL = 'http://192.168.31.101/spineup/v1';

function sendRequest(string $method, string $url, ?array $body = null, ?string $token = null): array {
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

echo "\n========================================================\n";
echo "  全量接口测试汇总: 通过 {$pass} 项 / 失败 {$fail} 项\n";
echo "========================================================\n";
exit($fail === 0 ? 0 : 1);
