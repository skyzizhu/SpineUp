<?php
declare(strict_types=1);

return [
    'app_name' => 'SpineUp API',
    'version'  => '1.0.0',
    'debug'    => (bool)($_ENV['APP_DEBUG'] ?? true),
    'timezone' => 'Asia/Shanghai',

    // JWT 签名密钥
    'jwt_secret'     => $_ENV['JWT_SECRET'] ?? 'spineup_super_secret_jwt_key_2026',
    'jwt_expire_sec' => 86400 * 30, // 30天免重新认证

    // 默认姿态工效学阈值
    'ergonomics' => [
        'slight_slump_threshold' => 15.0,
        'severe_slump_threshold' => 30.0,
        'energy_coins_per_minute' => 1,
        'streak_bonus_multiplier' => 1.5,
    ],
];
