<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class LogController
{
    /** @var PDO */
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 接收客户端硬件、耳机与异常埋点日志上报
     * POST /v1/logs/client
     */
    public function uploadClientLogs()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        $userId = $currentUser ? (int)$currentUser['uid'] : null;

        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        // 支持单条、包含 logs 键或批量日志数组上报
        if (isset($body['logs']) && is_array($body['logs'])) {
            $logs = $body['logs'];
        } elseif (isset($body[0]) && is_array($body[0])) {
            $logs = $body;
        } else {
            $logs = [$body];
        }

        $stmt = $this->db->prepare("
            INSERT INTO su_client_logs (
                user_id, category, level, message, context_json, client_time
            ) VALUES (?, ?, ?, ?, ?, ?)
        ");

        $count = 0;
        foreach ($logs as $log) {
            $category = (string)($log['category'] ?? 'Motion');
            $level = strtoupper((string)($log['level'] ?? 'INFO'));
            $message = mb_substr((string)($log['message'] ?? 'Client log'), 0, 500);
            $context = isset($log['context']) ? json_encode($log['context'], JSON_UNESCAPED_UNICODE) : null;
            $clientTime = (string)($log['client_time'] ?? date('Y-m-d H:i:s'));

            $stmt->execute([$userId, $category, $level, $message, $context, $clientTime]);
            $count++;
        }

        Response::json([
            'received' => true,
            'count'    => $count,
        ], 'Client logs stored successfully');
    }
}
