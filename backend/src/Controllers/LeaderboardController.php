<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class LeaderboardController
{
    /** @var PDO */
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 获取三大正向排行榜 (骨气能量榜 / 挺拔大师榜 / 连续毅力榜)
     * GET /v1/leaderboard?type=energy|quality|streak&page=1&page_size=20
     */
    public function getLeaderboard()
    {
        $type = (string)($_GET['type'] ?? 'energy');
        $page = max(1, (int)($_GET['page'] ?? 1));
        $pageSize = min(100, max(5, (int)($_GET['page_size'] ?? 20)));
        $offset = ($page - 1) * $pageSize;

        // 根据榜单类型决定排序列与显示字段
        switch ($type) {
            case 'quality':
                $orderCol = 'best_quality_ratio';
                $metricName = 'quality_ratio';
                $defaultSort = 'DESC';
                break;
            case 'streak':
                $orderCol = 'streak_days';
                $metricName = 'streak_days';
                $defaultSort = 'DESC';
                break;
            default:
                $orderCol = 'energy_coins';
                $metricName = 'energy_coins';
                $defaultSort = 'DESC';
                break;
        }

        // 获取前 N 名榜单列表
        $sql = "
            SELECT u.id, u.nickname, u.streak_days, u.energy_coins, u.best_quality_ratio,
                   COALESCE(s.active_persona_id, 'worker') AS active_persona_id
            FROM su_users u
            LEFT JOIN su_user_settings s ON u.id = s.user_id
            ORDER BY u.{$orderCol} {$defaultSort}, u.energy_coins DESC, u.id ASC
            LIMIT ? OFFSET ?
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(1, $pageSize, PDO::PARAM_INT);
        $stmt->bindValue(2, $offset, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll();

        $topList = [];
        $rankIndex = $offset + 1;
        foreach ($rows as $row) {
            switch ($type) {
                case 'quality':
                    $metricValue = (float)$row['best_quality_ratio'];
                    break;
                case 'streak':
                    $metricValue = (int)$row['streak_days'];
                    break;
                default:
                    $metricValue = (int)$row['energy_coins'];
                    break;
            }

            $topList[] = [
                'rank'          => $rankIndex++,
                'user_id'       => (int)$row['id'],
                'user_name'     => (string)$row['nickname'],
                'value'         => $metricValue,
                'metric_name'   => $metricName,
                'avatar_id'     => (string)$row['active_persona_id'],
                'streak_days'   => (int)$row['streak_days'],
                'energy_coins'  => (int)$row['energy_coins'],
                'quality_ratio' => (float)$row['best_quality_ratio'],
            ];
        }

        // 计算当前用户的个人排名
        $myRankData = null;
        $currentUser = AuthMiddleware::getCurrentUser();
        if ($currentUser) {
            $myUserId = (int)$currentUser['uid'];
            $myUserStmt = $this->db->prepare("
                SELECT u.id, u.nickname, u.streak_days, u.energy_coins, u.best_quality_ratio,
                       COALESCE(s.active_persona_id, 'worker') AS active_persona_id
                FROM su_users u
                LEFT JOIN su_user_settings s ON u.id = s.user_id
                WHERE u.id = ?
            ");
            $myUserStmt->execute([$myUserId]);
            $myUser = $myUserStmt->fetch();

            if ($myUser) {
                $myVal = $myUser[$orderCol];
                // 统计高于当前用户数值的人数得到排名
                $rankStmt = $this->db->prepare("
                    SELECT COUNT(*) AS ahead_count
                    FROM su_users
                    WHERE {$orderCol} > ? OR ({$orderCol} = ? AND id < ?)
                ");
                $rankStmt->execute([$myVal, $myVal, $myUserId]);
                $ahead = (int)($rankStmt->fetch()['ahead_count'] ?? 0);
                $myRank = $ahead + 1;

                switch ($type) {
                    case 'quality':
                        $myMetricValue = (float)$myUser['best_quality_ratio'];
                        break;
                    case 'streak':
                        $myMetricValue = (int)$myUser['streak_days'];
                        break;
                    default:
                        $myMetricValue = (int)$myUser['energy_coins'];
                        break;
                }

                $myRankData = [
                    'rank'          => $myRank,
                    'user_id'       => $myUserId,
                    'user_name'     => (string)$myUser['nickname'],
                    'value'         => $myMetricValue,
                    'metric_name'   => $metricName,
                    'avatar_id'     => (string)$myUser['active_persona_id'],
                    'streak_days'   => (int)$myUser['streak_days'],
                    'energy_coins'  => (int)$myUser['energy_coins'],
                    'quality_ratio' => (float)$myUser['best_quality_ratio'],
                ];
            }
        }

        // 统计总参与人数
        $cntStmt = $this->db->query("SELECT COUNT(*) AS total FROM su_users");
        $totalUsers = (int)($cntStmt->fetch()['total'] ?? count($topList));

        Response::json([
            'board_type'         => $type,
            'page'               => $page,
            'my_rank'            => $myRankData,
            'top_list'           => $topList,
            'total_participants' => $totalUsers,
            'positive_policy'    => 'Strictly positive gamification only; zero negative ranking.',
        ], 'Leaderboard retrieved');
    }

    /**
     * 更新用户个性昵称 / Callsign (含敏感词基础过滤与长度校验)
     * PUT /v1/users/profile
     */
    public function updateProfile()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $nickname = trim((string)($body['nickname'] ?? $body['user_name'] ?? ''));

        if (mb_strlen($nickname) < 1 || mb_strlen($nickname) > 32) {
            Response::error('昵称长度需在 1 到 32 个字符之间', 400, 400);
        }

        // 基础 XSS 与非法字符清洗
        $nickname = htmlspecialchars(strip_tags($nickname), ENT_QUOTES, 'UTF-8');

        // 常见敏感词/违禁词过滤
        $bannedWords = ['admin', 'root', 'system', '官方', '客服', '操你', '傻逼', '色情'];
        foreach ($bannedWords as $bad) {
            if (mb_stripos($nickname, $bad) !== false) {
                Response::error('昵称包含敏感词，请重新输入', 400, 400);
            }
        }

        $stmt = $this->db->prepare("UPDATE su_users SET nickname = ? WHERE id = ?");
        $stmt->execute([$nickname, $userId]);

        Response::json([
            'updated'   => true,
            'user_id'   => $userId,
            'nickname'  => $nickname,
        ], 'Profile updated successfully');
    }
}
