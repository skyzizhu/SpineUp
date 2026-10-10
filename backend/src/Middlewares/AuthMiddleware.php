<?php
declare(strict_types=1);

namespace App\Middlewares;

use App\Common\Database;
use App\Common\JWT;
use App\Common\Response;

class AuthMiddleware
{
    /** @var array|null */
    private static $currentUser = null;

    public function handle()
    {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            Response::error('Missing or invalid Authorization header', 401, 401);
        }

        $token = $matches[1];
        $config = require __DIR__ . '/../../config/app.php';
        $payload = JWT::decode($token, $config['jwt_secret']);

        if (!$payload || !isset($payload['uid'])) {
            Response::error('Invalid or expired token', 401, 401);
        }

        // 校验当前用户在数据库中是否真实存在 (防范数据库重建/环境切换后历史 Token 导致外键异常)
        try {
            $db = Database::getInstance();
            $stmt = $db->prepare("SELECT id FROM su_users WHERE id = ?");
            $stmt->execute([(int)$payload['uid']]);
            if (!$stmt->fetch()) {
                Response::error('User session expired or user not found, please re-authenticate', 401, 401);
            }
        } catch (\PDOException $e) {
            Response::error('Database authentication check failed', 500, 500);
        }

        self::$currentUser = $payload;
    }

    /**
     * @return array|null
     */
    public static function getCurrentUser()
    {
        return self::$currentUser;
    }
}
