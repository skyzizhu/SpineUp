<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Response;
use App\Services\AIService;

class AIController
{
    private AIService $aiService;

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
    public function reminder(): void
    {
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        $persona = (string)($body['persona'] ?? 'worker');
        $angleDeg = (float)($body['angleDeg'] ?? 20.0);
        $durationSec = (float)($body['durationSec'] ?? 5.0);
        $state = (string)($body['state'] ?? 'slightSlump');
        $systemPrompt = isset($body['systemPrompt']) ? (string)$body['systemPrompt'] : null;
        $userPrompt = isset($body['userPrompt']) ? (string)$body['userPrompt'] : null;

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
}
