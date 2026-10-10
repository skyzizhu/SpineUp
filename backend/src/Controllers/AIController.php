<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Response;
use App\Services\AIService;

class AIController
{
    /** @var AIService */
    private $aiService;

    public function __construct()
    {
        $this->aiService = new AIService();
    }

    /**
     * 实时体态违规拟人化提醒接口
     * 直接对接 iOS 客户端 SUCloudAIEngine.swift
     *
     * POST /v1/ai/reminder
     */
    public function reminder()
    {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $persona = \App\Common\Security::validateEnum((string)($body['persona'] ?? 'worker'), ['worker', 'cat', 'coach', 'anime'], 'worker');
        $angleDeg = \App\Common\Security::validateFloat($body['angleDeg'] ?? 20.0, -90.0, 90.0, 20.0);
        $durationSec = \App\Common\Security::validateFloat($body['durationSec'] ?? 5.0, 0.0, 86400.0, 5.0);
        $state = \App\Common\Security::validateEnum((string)($body['state'] ?? 'slightSlump'), ['upright', 'slightSlump', 'severeSlump'], 'slightSlump');
        $systemPrompt = isset($body['systemPrompt']) ? \App\Common\Security::cleanString((string)$body['systemPrompt'], 2000) : null;
        $userPrompt = isset($body['userPrompt']) ? \App\Common\Security::cleanString((string)$body['userPrompt'], 1000) : null;

        $reminderText = $this->aiService->generateReminder(
            $persona,
            $angleDeg,
            $durationSec,
            $state,
            $systemPrompt,
            $userPrompt
        );

        // 格式完美对齐 iOS 端的 ReminderResponse (code, reminderText)
        echo json_encode([
            'code'         => 200,
            'reminderText' => $reminderText,
            'timestamp'    => time(),
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    /**
     * AI 深度危害透视推演
     * POST /v1/ai/posture-hazard
     */
    public function postureHazard()
    {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $pitchDeg = \App\Common\Security::validateFloat($body['pitchDeg'] ?? $body['pitch_deg'] ?? 0.0, -90.0, 90.0, 0.0);
        $extraLoadKg = \App\Common\Security::validateFloat($body['extraLoadKg'] ?? $body['extra_load_kg'] ?? 0.0, 0.0, 100.0, 0.0);
        $slumpDurationSec = \App\Common\Security::validateFloat($body['slumpDurationSec'] ?? $body['slump_duration_sec'] ?? 0.0, 0.0, 86400.0, 0.0);
        $violationsCount = \App\Common\Security::validateInt($body['violationsCount'] ?? $body['violations_count'] ?? 0, 0, 10000, 0);
        $persona = \App\Common\Security::validateEnum((string)($body['persona'] ?? 'worker'), ['worker', 'cat', 'coach', 'anime'], 'worker');
        $userName = \App\Common\Security::cleanString((string)($body['userName'] ?? $body['user_name'] ?? '挺拔打工人'), 32);
        $locale = \App\Common\Security::cleanString((string)($body['locale'] ?? 'zh-Hans'), 16);

        $startMs = (int)(microtime(true) * 1000);
        $result = $this->aiService->analyzeHazard(
            $pitchDeg,
            $extraLoadKg,
            $slumpDurationSec,
            $violationsCount,
            $persona,
            $userName,
            $locale
        );
        $latencyMs = (int)(microtime(true) * 1000) - $startMs;

        // 异步/容错记录到 su_ai_consultation_logs
        try {
            $db = \App\Common\Database::getInstance();
            $stmt = $db->prepare("
                INSERT INTO su_ai_consultation_logs (
                    user_id, request_type, persona_id, context_pitch_deg, context_extra_load_kg,
                    input_payload_json, ai_response_json, latency_ms, is_cached
                ) VALUES (?, 'HAZARD_PERSPECTIVE', ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $body['userId'] ?? null,
                $persona,
                $pitchDeg,
                $extraLoadKg,
                $raw,
                json_encode($result, JSON_UNESCAPED_UNICODE),
                $latencyMs,
                !empty($result['is_cached']) ? 1 : 0,
            ]);
        } catch (\Throwable $e) {
            // 日志落库失败不阻断核心返回
        }

        Response::json($result, 'AI Hazard report generated');
    }

    /**
     * AI 定制 30 秒急救减负处方
     * POST /v1/ai/relief-prescription
     */
    public function reliefPrescription()
    {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $pitchDeg = (float)($body['pitchDeg'] ?? $body['pitch_deg'] ?? 0.0);
        $extraLoadKg = (float)($body['extraLoadKg'] ?? $body['extra_load_kg'] ?? 0.0);
        $persona = (string)($body['persona'] ?? 'worker');
        $locale = (string)($body['locale'] ?? 'zh-Hans');

        $startMs = (int)(microtime(true) * 1000);
        $result = $this->aiService->generateReliefPrescription(
            $pitchDeg,
            $extraLoadKg,
            $persona,
            $locale
        );
        $latencyMs = (int)(microtime(true) * 1000) - $startMs;

        try {
            $db = \App\Common\Database::getInstance();
            $stmt = $db->prepare("
                INSERT INTO su_ai_consultation_logs (
                    user_id, request_type, persona_id, context_pitch_deg, context_extra_load_kg,
                    input_payload_json, ai_response_json, latency_ms, is_cached
                ) VALUES (?, 'RELIEF_PRESCRIPTION', ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $body['userId'] ?? null,
                $persona,
                $pitchDeg,
                $extraLoadKg,
                $raw,
                json_encode($result, JSON_UNESCAPED_UNICODE),
                $latencyMs,
                !empty($result['is_cached']) ? 1 : 0,
            ]);
        } catch (\Throwable $e) {
            // 忽略非关键错误
        }

        Response::json($result, 'AI Relief prescription generated');
    }
}
