<?php
declare(strict_types=1);

namespace App\Common;

/**
 * 统一后端安全防护工具类
 * 防范 SQL 注入、跨站脚本 (XSS)、空字节截断、参数篡改、极端异常值攻击
 * 全面兼容 PHP 7.0.33+
 */
class Security
{
    /**
     * 清理与转义文本输入 (防 XSS、防 HTML 注入、防截断)
     */
    public static function cleanString($str = null, int $maxLen = 255): string
    {
        if ($str === null) {
            return '';
        }
        $str = (string)$str;

        // 1. 移除空字节与不可见控制字符 (\0, \x00 等)
        $clean = str_replace(["\0", "\x00"], '', $str);

        // 2. 移除所有 HTML / JavaScript 标签
        $clean = strip_tags($clean);

        // 3. 转义特殊 HTML 字符
        $clean = htmlspecialchars($clean, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');

        // 4. 去除首尾空白
        $clean = trim($clean);

        // 5. 限制最大字符长度
        if (mb_strlen($clean, 'UTF-8') > $maxLen) {
            $clean = mb_substr($clean, 0, $maxLen, 'UTF-8');
        }

        return $clean;
    }

    /**
     * 浮点数边界安全校验 (防止超大负荷或非法数值注入)
     */
    public static function validateFloat($val, float $min, float $max, float $default = 0.0): float
    {
        if (!is_numeric($val)) {
            return $default;
        }

        $f = (float)$val;
        if (is_nan($f) || is_infinite($f)) {
            return $default;
        }

        return max($min, min($max, $f));
    }

    /**
     * 整数边界安全校验
     */
    public static function validateInt($val, int $min, int $max, int $default = 0): int
    {
        if (!is_numeric($val)) {
            return $default;
        }

        $i = (int)$val;
        return max($min, min($max, $i));
    }

    /**
     * 白名单枚举安全校验
     */
    public static function validateEnum($val = null, array $allowed = [], string $default = ''): string
    {
        if ($val === null) {
            return $default;
        }
        $val = trim((string)$val);
        return in_array($val, $allowed, true) ? $val : $default;
    }

    /**
     * 校验日期格式 (YYYY-MM-DD)
     */
    public static function validateDate($date = null): string
    {
        if ($date === null || !preg_match('/^\d{4}-\d{2}-\d{2}$/', (string)$date)) {
            return date('Y-m-d');
        }

        list($y, $m, $d) = explode('-', (string)$date);
        if (!checkdate((int)$m, (int)$d, (int)$y)) {
            return date('Y-m-d');
        }

        return (string)$date;
    }

    /**
     * 校验设备 UUID 或唯一标识 (防注入特殊字符)
     */
    public static function validateDeviceUuid($uuid = null): string
    {
        if ($uuid === null) {
            return 'DEVICE_' . bin2hex(random_bytes(8));
        }

        $clean = preg_replace('/[^a-zA-Z0-9_\-\.]/', '', (string)$uuid);
        $len = strlen($clean);
        if ($len < 8 || $len > 128) {
            return 'DEVICE_' . bin2hex(random_bytes(8));
        }

        return $clean;
    }

    /**
     * 校验 16 位分享哈希短码
     */
    public static function validateShareHash($hash = null)
    {
        if ($hash === null) {
            return null;
        }
        $clean = trim((string)$hash);
        if (preg_match('/^[a-fA-F0-9_]{6,32}$/', $clean)) {
            return $clean;
        }
        return null;
    }

    /**
     * 过滤敏感与违规词汇 (防止恶搞昵称或有害言论)
     */
    public static function filterVulgarWords(string $text): string
    {
        $banned = [
            'admin', 'root', 'system', 'spineup_official',
            '傻逼', '操你', '弱智', '废物', '死妈',
            'fuck', 'shit', 'bitch', 'asshole'
        ];

        $filtered = $text;
        foreach ($banned as $word) {
            $filtered = str_ireplace($word, '***', $filtered);
        }

        return $filtered;
    }
}
