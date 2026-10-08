<?php
declare(strict_types=1);

namespace App\Common;

class Response
{
    /**
     * 发送标准成功响应
     */
    public static function json(mixed $data = [], string $message = 'success', int $code = 200, int $httpStatus = 200): void
    {
        http_response_code($httpStatus);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

        echo json_encode([
            'code'      => $code,
            'message'   => $message,
            'data'      => $data,
            'timestamp' => time(),
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    /**
     * 发送错误响应
     */
    public static function error(string $message = 'error', int $code = 400, int $httpStatus = 400, mixed $details = null): void
    {
        http_response_code($httpStatus);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

        $payload = [
            'code'      => $code,
            'message'   => $message,
            'timestamp' => time(),
        ];
        if ($details !== null) {
            $payload['details'] = $details;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}
