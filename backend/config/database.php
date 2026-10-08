<?php
declare(strict_types=1);

return [
    'driver'   => $_ENV['DB_DRIVER'] ?? 'mysql', // 'mysql' 或 'sqlite'

    // MySQL 配置 (XAMPP 默认 host: 127.0.0.1, user: root, password: '')
    'mysql' => [
        'host'     => $_ENV['DB_HOST'] ?? '127.0.0.1',
        'port'     => (int)($_ENV['DB_PORT'] ?? 3306),
        'dbname'   => $_ENV['DB_NAME'] ?? 'spineup',
        'username' => $_ENV['DB_USER'] ?? 'root',
        'password' => $_ENV['DB_PASS'] ?? '',
        'charset'  => 'utf8mb4',
        'options'  => [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ],
    ],

    // SQLite 本地零依赖备用模式 (用于单机免配置开发与自动化测试)
    'sqlite' => [
        'database' => __DIR__ . '/../storage/spineup_dev.sqlite',
    ]
];
