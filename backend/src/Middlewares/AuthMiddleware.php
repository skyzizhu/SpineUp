<?php
declare(strict_types=1);

namespace App\Middlewares;

use App\Common\JWT;
use App\Common\Response;

class AuthMiddleware
{
    private static ?array $currentUser = null;

    public function handle(): void
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

        self::$currentUser = $payload;
    }

    public static function getCurrentUser(): ?array
    {
        return self::$currentUser;
    }
}
