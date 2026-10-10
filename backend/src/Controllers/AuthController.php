<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\JWT;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use PDO;

class AuthController
{
    /** @var PDO */
    private $db;

    /** @var array */
    private $appConfig;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->appConfig = require __DIR__ . '/../../config/app.php';
    }

    /**
     * 匿名访客注册/免密秒开
     * POST /v1/auth/guest
     */
    public function guest()
    {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $deviceUuid = trim((string)($body['deviceUuid'] ?? ''));
        if (empty($deviceUuid)) {
            $deviceUuid = self::generateUuidV4();
        }

        $deviceModel = (string)($body['deviceModel'] ?? 'iPhone');
        $locale = (string)($body['locale'] ?? 'zh-Hans');
        $preferredPersona = \App\Common\Security::validateEnum((string)($body['preferredPersona'] ?? 'worker'), ['worker', 'cat', 'coach', 'anime'], 'worker');

        // 查询或创建访客用户
        $stmt = $this->db->prepare("SELECT id, user_uuid, is_guest, nickname FROM su_users WHERE user_uuid = ?");
        $stmt->execute([$deviceUuid]);
        $user = $stmt->fetch();

        if (!$user) {
            $insert = $this->db->prepare("
                INSERT INTO su_users (user_uuid, is_guest, nickname, locale)
                VALUES (?, 1, 'SpineUp 体验官', ?)
            ");
            $insert->execute([$deviceUuid, $locale]);
            $userId = (int)$this->db->lastInsertId();

            // 初始化设置
            $initSettings = $this->db->prepare("
                INSERT INTO su_user_settings (user_id, active_persona_id, last_device_model)
                VALUES (?, ?, ?)
            ");
            $initSettings->execute([$userId, $preferredPersona, $deviceModel]);
        } else {
            $userId = (int)$user['id'];
        }

        $token = JWT::encode([
            'uid'     => $userId,
            'uuid'    => $deviceUuid,
            'isGuest' => true,
        ], $this->appConfig['jwt_secret'], $this->appConfig['jwt_expire_sec']);

        Response::json([
            'token'    => $token,
            'userId'   => $userId,
            'userUuid' => $deviceUuid,
            'isGuest'  => true,
        ], 'Guest session initialized');
    }

    /**
     * 获取当前用户信息与偏好
     * GET /v1/users/me
     */
    public function me()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = $currentUser['uid'];
        $stmt = $this->db->prepare("
            SELECT u.id, u.user_uuid, u.nickname, u.is_guest, u.locale,
                   s.active_persona_id, s.calibration_base_pitch, s.calibration_base_roll,
                   s.slight_slump_threshold, s.severe_slump_threshold,
                   s.is_sound_enabled, s.is_haptic_enabled, s.is_voice_enabled
            FROM su_users u
            LEFT JOIN su_user_settings s ON u.id = s.user_id
            WHERE u.id = ?
        ");
        $stmt->execute([$userId]);
        $data = $stmt->fetch();

        if (!$data) {
            Response::error('User not found', 404, 404);
        }

        Response::json($data);
    }

    /**
     * 更新用户设置 (校准零点、阈值、人设)
     * PUT /v1/users/settings
     */
    public function updateSettings()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = $currentUser['uid'];
        $body = json_decode(file_get_contents('php://input'), true) ?? [];

        $persona = isset($body['activePersonaId']) ? \App\Common\Security::validateEnum((string)$body['activePersonaId'], ['worker', 'cat', 'coach', 'anime'], 'worker') : null;
        $pitch = isset($body['calibrationBasePitch']) ? \App\Common\Security::validateFloat($body['calibrationBasePitch'], -90.0, 90.0, 0.0) : null;
        $roll = isset($body['calibrationBaseRoll']) ? \App\Common\Security::validateFloat($body['calibrationBaseRoll'], -90.0, 90.0, 0.0) : null;
        $slightThresh = isset($body['slightSlumpThreshold']) ? \App\Common\Security::validateFloat($body['slightSlumpThreshold'], 5.0, 45.0, 15.0) : null;
        $severeThresh = isset($body['severeSlumpThreshold']) ? \App\Common\Security::validateFloat($body['severeSlumpThreshold'], 15.0, 85.0, 30.0) : null;

        $stmt = $this->db->prepare("
            UPDATE su_user_settings
            SET active_persona_id = COALESCE(?, active_persona_id),
                calibration_base_pitch = COALESCE(?, calibration_base_pitch),
                calibration_base_roll = COALESCE(?, calibration_base_roll),
                slight_slump_threshold = COALESCE(?, slight_slump_threshold),
                severe_slump_threshold = COALESCE(?, severe_slump_threshold)
            WHERE user_id = ?
        ");
        $stmt->execute([
            $persona,
            $pitch,
            $roll,
            $slightThresh,
            $severeThresh,
            $userId,
        ]);

        Response::json(['updated' => true], 'Settings updated');
    }

    private static function generateUuidV4(): string
    {
        $data = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
}
