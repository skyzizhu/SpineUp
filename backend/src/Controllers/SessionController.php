<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class SessionController
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 姿态监测会话数据同步
     * POST /v1/sessions/sync
     */
    public function sync(): void
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $sessionDate = (string)($body['date'] ?? date('Y-m-d'));
        $uprightSec = (float)($body['uprightDurationSec'] ?? 0.0);
        $slumpSec = (float)($body['slumpDurationSec'] ?? 0.0);
        $longestStreak = (float)($body['longestStreakSec'] ?? 0.0);
        $extraLoadKg = (float)($body['accumulatedExtraLoadKg'] ?? 0.0);
        $violations = (int)($body['violationsCount'] ?? 0);
        $score = (int)($body['score'] ?? 100);
        $grade = (string)($body['grade'] ?? 'S');

        // 计算骨气能量币 (每挺拔 60 秒得 1 币)
        $todayCoins = (int)floor($uprightSec / 60.0);

        // 插入或更新每日会话记录 (兼容 MySQL 与 SQLite)
        $driver = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME);
        if ($driver === 'sqlite') {
            $sql = "
                INSERT INTO su_posture_sessions (
                    user_id, session_date, upright_duration_sec, slump_duration_sec,
                    longest_streak_sec, accumulated_extra_load_kg, violations_count, score, grade, synced_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
                ON CONFLICT(user_id, session_date) DO UPDATE SET
                    upright_duration_sec = excluded.upright_duration_sec,
                    slump_duration_sec = excluded.slump_duration_sec,
                    longest_streak_sec = excluded.longest_streak_sec,
                    accumulated_extra_load_kg = excluded.accumulated_extra_load_kg,
                    violations_count = excluded.violations_count,
                    score = excluded.score,
                    grade = excluded.grade,
                    synced_at = datetime('now');
            ";
        } else {
            $sql = "
                INSERT INTO su_posture_sessions (
                    user_id, session_date, upright_duration_sec, slump_duration_sec,
                    longest_streak_sec, accumulated_extra_load_kg, violations_count, score, grade, synced_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                ON DUPLICATE KEY UPDATE
                    upright_duration_sec = VALUES(upright_duration_sec),
                    slump_duration_sec = VALUES(slump_duration_sec),
                    longest_streak_sec = VALUES(longest_streak_sec),
                    accumulated_extra_load_kg = VALUES(accumulated_extra_load_kg),
                    violations_count = VALUES(violations_count),
                    score = VALUES(score),
                    grade = VALUES(grade),
                    synced_at = NOW();
            ";
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            $userId, $sessionDate, $uprightSec, $slumpSec,
            $longestStreak, $extraLoadKg, $violations, $score, $grade
        ]);

        Response::json([
            'synced'          => true,
            'todayTotalCoins' => $todayCoins,
            'streakDays'      => 3,
        ], 'Session synchronized');
    }
}
