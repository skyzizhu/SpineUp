<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class SessionController
{
    /** @var PDO */
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 姿态监测会话数据同步
     * POST /v1/sessions/sync
     */
    public function sync()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        // 使用 Security 进行安全边界校验与防作弊
        $sessionDate = \App\Common\Security::validateDate((string)($body['date'] ?? null));
        $uprightSec = \App\Common\Security::validateFloat($body['uprightDurationSec'] ?? 0.0, 0.0, 86400.0, 0.0);
        $slumpSec = \App\Common\Security::validateFloat($body['slumpDurationSec'] ?? 0.0, 0.0, 86400.0, 0.0);
        $longestStreak = \App\Common\Security::validateFloat($body['longestStreakSec'] ?? 0.0, 0.0, 86400.0, 0.0);
        $extraLoadKg = \App\Common\Security::validateFloat($body['accumulatedExtraLoadKg'] ?? 0.0, 0.0, 5000.0, 0.0);
        $violations = \App\Common\Security::validateInt($body['violationsCount'] ?? 0, 0, 10000, 0);
        $score = \App\Common\Security::validateInt($body['score'] ?? 100, 0, 100, 100);
        $grade = \App\Common\Security::validateEnum((string)($body['grade'] ?? 'S'), ['S', 'A', 'B', 'C', 'D'], 'S');

        // 单日时间超限防刷保护
        if (($uprightSec + $slumpSec) > 86400.0) {
            $uprightSec = min(86400.0, $uprightSec);
            $slumpSec = 86400.0 - $uprightSec;
        }

        // 计算骨气能量币 (每挺拔 60 秒得 1 币，单日最多 200 币防刷)
        $todayCoins = min(200, (int)floor($uprightSec / 60.0));

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

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $userId, $sessionDate, $uprightSec, $slumpSec,
                $longestStreak, $extraLoadKg, $violations, $score, $grade
            ]);

            // 同步更新 su_users 统计数值以参与排行榜动态竞争
            $totalDur = $uprightSec + $slumpSec;
            $quality = $totalDur > 0 ? round(($uprightSec / $totalDur) * 100.0, 1) : 100.0;
            $nowSql = ($driver === 'sqlite') ? "datetime('now')" : "NOW()";
            $updateUser = $this->db->prepare("
                UPDATE su_users
                SET energy_coins = energy_coins + ?,
                    best_quality_ratio = CASE WHEN best_quality_ratio < ? THEN ? ELSE best_quality_ratio END,
                    streak_days = CASE WHEN streak_days < 1 THEN 1 ELSE streak_days END,
                    updated_at = {$nowSql}
                WHERE id = ?
            ");
            $updateUser->execute([$todayCoins, $quality, $quality, $userId]);

            // 读取当前用户最新的连续天数与总币数
            $userRowStmt = $this->db->prepare("SELECT streak_days, energy_coins FROM su_users WHERE id = ?");
            $userRowStmt->execute([$userId]);
            $uRow = $userRowStmt->fetch() ?: ['streak_days' => 1, 'energy_coins' => $todayCoins];

            Response::json([
                'synced'          => true,
                'todayTotalCoins' => (int)$uRow['energy_coins'],
                'streakDays'      => (int)$uRow['streak_days'],
            ], 'Session synchronized');
        } catch (\PDOException $e) {
            Response::error('Database sync error: ' . $e->getMessage(), 500, 500);
        }
    }

    /**
     * 获取近 N 天姿态监测会话历史
     * GET /v1/sessions/history?days=7
     */
    public function history()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $days = max(1, min(60, (int)($_GET['days'] ?? 7)));
        $startDate = date('Y-m-d', strtotime("-" . ($days - 1) . " days"));

        $stmt = $this->db->prepare("
            SELECT * FROM su_posture_sessions
            WHERE user_id = ? AND session_date >= ?
            ORDER BY session_date ASC
        ");
        $stmt->execute([$userId, $startDate]);
        $sessions = $stmt->fetchAll();

        Response::json($sessions, 'Session history retrieved');
    }
}
