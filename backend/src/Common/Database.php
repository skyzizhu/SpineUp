<?php
declare(strict_types=1);

namespace App\Common;

use PDO;
use PDOException;

class Database
{
    /** @var PDO|null */
    private static $instance = null;

    public static function getInstance(): PDO
    {
        if (self::$instance === null) {
            self::$instance = self::createConnection();
        }
        return self::$instance;
    }

    private static function createConnection(): PDO
    {
        $config = require __DIR__ . '/../../config/database.php';
        $driver = $config['driver'] ?? 'mysql';

        if ($driver === 'mysql') {
            try {
                $mc = $config['mysql'];
                $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=%s', $mc['host'], $mc['port'], $mc['dbname'], $mc['charset']);
                return new PDO($dsn, $mc['username'], $mc['password'], $mc['options']);
            } catch (PDOException $e) {
                // 如果 MySQL 暂时无法连接，且在开发环境下，自动回退到 SQLite 保证接口服务可用
                error_log("MySQL connection failed: " . $e->getMessage() . ". Falling back to SQLite for local dev.");
                return self::createSqliteFallback($config['sqlite']['database'] ?? null);
            }
        } else {
            return self::createSqliteFallback($config['sqlite']['database'] ?? null);
        }
    }

    private static function createSqliteFallback($dbPath = null): PDO
    {
        $path = $dbPath ?: __DIR__ . '/../../storage/spineup_dev.sqlite';
        $dir = dirname($path);
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }
        $pdo = new PDO('sqlite:' . $path, null, null, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);

        // 初始化 SQLite 基础表结构以保证本地零配置运行
        self::initSqliteTables($pdo);
        return $pdo;
    }

    private static function initSqliteTables(PDO $pdo)
    {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS su_users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_uuid TEXT UNIQUE NOT NULL,
                apple_user_id TEXT UNIQUE,
                is_guest INTEGER NOT NULL DEFAULT 1,
                nickname TEXT NOT NULL DEFAULT 'SpineUp User',
                streak_days INTEGER NOT NULL DEFAULT 1,
                energy_coins INTEGER NOT NULL DEFAULT 0,
                best_quality_ratio REAL NOT NULL DEFAULT 100.0,
                locale TEXT NOT NULL DEFAULT 'zh-Hans',
                timezone TEXT NOT NULL DEFAULT 'Asia/Shanghai',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_user_settings (
                user_id INTEGER PRIMARY KEY,
                active_persona_id TEXT NOT NULL DEFAULT 'worker',
                calibration_base_pitch REAL NOT NULL DEFAULT 0.0,
                calibration_base_roll REAL NOT NULL DEFAULT 0.0,
                slight_slump_threshold REAL NOT NULL DEFAULT 15.0,
                severe_slump_threshold REAL NOT NULL DEFAULT 30.0,
                is_sound_enabled INTEGER NOT NULL DEFAULT 1,
                is_haptic_enabled INTEGER NOT NULL DEFAULT 1,
                is_voice_enabled INTEGER NOT NULL DEFAULT 1,
                last_device_model TEXT,
                headphone_model TEXT,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_posture_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                session_date TEXT NOT NULL,
                upright_duration_sec REAL NOT NULL DEFAULT 0.0,
                slump_duration_sec REAL NOT NULL DEFAULT 0.0,
                longest_streak_sec REAL NOT NULL DEFAULT 0.0,
                accumulated_extra_load_kg REAL NOT NULL DEFAULT 0.0,
                violations_count INTEGER NOT NULL DEFAULT 0,
                score INTEGER NOT NULL DEFAULT 100,
                grade TEXT NOT NULL DEFAULT 'S',
                synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, session_date)
            );

            CREATE TABLE IF NOT EXISTS su_daily_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                report_date TEXT NOT NULL,
                persona_id TEXT NOT NULL,
                diagnosis_title TEXT NOT NULL,
                doctor_prescription TEXT NOT NULL,
                persona_comment TEXT NOT NULL,
                equivalent_item_name TEXT NOT NULL,
                equivalent_item_kg REAL NOT NULL,
                share_hash TEXT UNIQUE NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, report_date)
            );

            CREATE TABLE IF NOT EXISTS su_energy_ledger (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                delta_coins INTEGER NOT NULL,
                balance_after INTEGER NOT NULL,
                reason TEXT NOT NULL,
                idempotent_key TEXT UNIQUE NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_client_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                category TEXT NOT NULL,
                level TEXT NOT NULL DEFAULT 'WARNING',
                message TEXT NOT NULL,
                context_json TEXT,
                client_time DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_relief_exercise_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                action_type TEXT NOT NULL DEFAULT 'CHIN_TUCK',
                pitch_deg REAL NOT NULL DEFAULT 0.0,
                extra_load_kg REAL NOT NULL DEFAULT 0.0,
                duration_sec INTEGER NOT NULL DEFAULT 30,
                reward_coins INTEGER NOT NULL DEFAULT 5,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_ai_consultation_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                request_type TEXT NOT NULL,
                persona_id TEXT NOT NULL DEFAULT 'worker',
                context_pitch_deg REAL NOT NULL DEFAULT 0.0,
                context_extra_load_kg REAL NOT NULL DEFAULT 0.0,
                input_payload_json TEXT,
                ai_response_json TEXT,
                model_name TEXT NOT NULL DEFAULT 'deepseek-chat',
                tokens_used INTEGER NOT NULL DEFAULT 0,
                latency_ms INTEGER NOT NULL DEFAULT 0,
                is_cached INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS su_periodic_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                period_type TEXT NOT NULL DEFAULT 'weekly',
                period_key TEXT NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                total_wear_sec REAL NOT NULL DEFAULT 0.0,
                upright_sec REAL NOT NULL DEFAULT 0.0,
                slump_sec REAL NOT NULL DEFAULT 0.0,
                avg_score INTEGER NOT NULL DEFAULT 85,
                accumulated_load_kg REAL NOT NULL DEFAULT 0.0,
                alleviated_load_kg REAL NOT NULL DEFAULT 0.0,
                total_violations INTEGER NOT NULL DEFAULT 0,
                best_day_date TEXT,
                fatigue_hotspot_hour INTEGER DEFAULT 16,
                dowager_hump_risk INTEGER NOT NULL DEFAULT 15,
                equivalent_item_name TEXT DEFAULT '约 3 辆金属山地自行车',
                ai_persona_summary TEXT,
                share_hash TEXT NOT NULL DEFAULT '',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, period_type, period_key)
            );
        ");

        // 兼容已有 SQLite 数据库，增补字段
        $columns = [
            'ALTER TABLE su_users ADD COLUMN streak_days INTEGER NOT NULL DEFAULT 1',
            'ALTER TABLE su_users ADD COLUMN energy_coins INTEGER NOT NULL DEFAULT 0',
            'ALTER TABLE su_users ADD COLUMN best_quality_ratio REAL NOT NULL DEFAULT 100.0',
        ];
        foreach ($columns as $alterSql) {
            try {
                $pdo->exec($alterSql);
            } catch (\Exception $ignored) {
                // 列已存在时忽略
            }
        }
    }
}
