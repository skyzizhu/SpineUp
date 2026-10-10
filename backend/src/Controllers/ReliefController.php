<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class ReliefController
{
    /** @var PDO */
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 30 秒办公室减负微操打卡领能量
     * POST /v1/relief/claim
     */
    public function claim()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $actionType = (string)($body['action_type'] ?? $body['actionType'] ?? 'CHIN_TUCK');
        $pitchDeg = (float)($body['pitch_deg'] ?? $body['pitchDeg'] ?? 0.0);
        $extraLoadKg = (float)($body['extra_load_kg'] ?? $body['extraLoadKg'] ?? 0.0);
        $durationSec = max(10, min(120, (int)($body['duration_sec'] ?? $body['durationSec'] ?? 30)));
        $rewardCoins = 5;

        // 1. 防刷风控校验：检查距离上一次完成打卡的时间间隔 (至少间隔 25 秒)
        $latestStmt = $this->db->prepare("
            SELECT created_at
            FROM su_relief_exercise_logs
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 1
        ");
        $latestStmt->execute([$userId]);
        $latest = $latestStmt->fetch();

        if ($latest) {
            $lastTime = strtotime($latest['created_at']);
            if (time() - $lastTime < 25) {
                Response::error('休息一下，两次减负微操需间隔 30 秒哦', 429, 429);
            }
        }

        // 2. 每日打卡次数上限限制 (单日最多 15 次)
        $todayStart = date('Y-m-d 00:00:00');
        $countStmt = $this->db->prepare("
            SELECT COUNT(*) AS today_count
            FROM su_relief_exercise_logs
            WHERE user_id = ? AND created_at >= ?
        ");
        $countStmt->execute([$userId, $todayStart]);
        $todayCount = (int)($countStmt->fetch()['today_count'] ?? 0);

        if ($todayCount >= 15) {
            Response::error('今日减负微操能量奖励已达上限 (15次)，请明天继续保持！', 400, 400);
        }

        // 3. 事务处理：记录微操打卡表、更新用户能量币总额、插入账本流水
        $this->db->beginTransaction();
        try {
            // A. 插入打卡表
            $insertLog = $this->db->prepare("
                INSERT INTO su_relief_exercise_logs (
                    user_id, action_type, pitch_deg, extra_load_kg, duration_sec, reward_coins
                ) VALUES (?, ?, ?, ?, ?, ?)
            ");
            $insertLog->execute([$userId, $actionType, $pitchDeg, $extraLoadKg, $durationSec, $rewardCoins]);

            // B. 累加用户能量币
            $updateUser = $this->db->prepare("
                UPDATE su_users
                SET energy_coins = energy_coins + ?
                WHERE id = ?
            ");
            $updateUser->execute([$rewardCoins, $userId]);

            // 查询最新余额
            $userStmt = $this->db->prepare("SELECT energy_coins FROM su_users WHERE id = ?");
            $userStmt->execute([$userId]);
            $newBalance = (int)($userStmt->fetch()['energy_coins'] ?? $rewardCoins);

            // C. 记录能量账本
            $idempotentKey = sprintf('relief_%d_%s_%d', $userId, date('Ymd_His'), random_int(100, 999));
            $ledgerStmt = $this->db->prepare("
                INSERT INTO su_energy_ledger (
                    user_id, delta_coins, balance_after, reason, idempotent_key
                ) VALUES (?, ?, ?, 'RELIEF_EXERCISE_BONUS', ?)
            ");
            $ledgerStmt->execute([$userId, $rewardCoins, $newBalance, $idempotentKey]);

            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollBack();
            Response::error('打卡结算失败: ' . $e->getMessage(), 500, 500);
        }

        Response::json([
            'claimed'         => true,
            'reward_coins'    => $rewardCoins,
            'new_balance'     => $newBalance,
            'current_balance' => $newBalance,
            'action_type'     => $actionType,
            'today_count'     => $todayCount + 1,
            'today_completed' => $todayCount + 1,
        ], 'Relief exercise completed, energy coins granted');
    }
}
