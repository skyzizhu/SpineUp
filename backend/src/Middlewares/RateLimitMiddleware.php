<?php
declare(strict_types=1);

namespace App\Middlewares;

use App\Common\Response;

/**
 * 接口请求频率限制与防爆破防刷中间件 (Rate Limiter)
 * 防止恶意脚本利用抓包信息短时间泛洪请求、刷取能量币或消耗大模型 Token
 * 全面兼容 PHP 7.0.33+
 */
class RateLimitMiddleware
{
    /** @var string */
    private static $storageDir = __DIR__ . '/../../storage/ratelimit';

    public function handle()
    {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $ip = $this->getClientIp();

        // 确定限流策略组与单分钟请求配额
        $limit = 120; // 默认常规接口 120 次/分钟
        $group = 'general';

        if (strpos($uri, '/ai/') !== false) {
            $limit = 35; // AI 生成接口 35 次/分钟
            $group = 'ai';
        } elseif (strpos($uri, '/auth/') !== false) {
            $limit = 25; // 认证接口 25 次/分钟
            $group = 'auth';
        } elseif (strpos($uri, '/relief/') !== false) {
            $limit = 30; // 能量微操领取接口 30 次/分钟
            $group = 'relief';
        }

        $cacheKey = md5("{$ip}_{$group}");
        if (!$this->checkLimit($cacheKey, $limit, 60)) {
            header('Retry-After: 60');
            Response::error('请求过于频繁，系统已触发安全风控保护，请 1 分钟后再试 (429 Too Many Requests)', 429, 429);
        }
    }

    private function checkLimit(string $key, int $maxRequests, int $windowSec): bool
    {
        $dir = self::$storageDir;
        if (!is_dir($dir) || !is_writable($dir)) {
            @mkdir($dir, 0777, true);
        }
        if (!is_dir($dir) || !is_writable($dir)) {
            $dir = sys_get_temp_dir() . '/spineup_ratelimit';
            if (!is_dir($dir)) {
                @mkdir($dir, 0777, true);
            }
        }

        $filePath = $dir . "/rl_{$key}.json";
        $now = time();

        if (file_exists($filePath)) {
            $data = json_decode((string)@file_get_contents($filePath), true);
            if (is_array($data) && isset($data['start'], $data['count'])) {
                if ($now - $data['start'] < $windowSec) {
                    if ($data['count'] >= $maxRequests) {
                        return false;
                    }
                    $data['count']++;
                    @file_put_contents($filePath, json_encode($data), LOCK_EX);
                    return true;
                }
            }
        }

        // 新窗口
        $newData = [
            'start' => $now,
            'count' => 1,
        ];
        @file_put_contents($filePath, json_encode($newData), LOCK_EX);
        return true;
    }

    private function getClientIp(): string
    {
        if (!empty($_SERVER['HTTP_CF_CONNECTING_IP'])) {
            return (string)$_SERVER['HTTP_CF_CONNECTING_IP'];
        }
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ips = explode(',', (string)$_SERVER['HTTP_X_FORWARDED_FOR']);
            return trim($ips[0]);
        }
        return (string)($_SERVER['REMOTE_ADDR'] ?? '127.0.0.1');
    }
}
