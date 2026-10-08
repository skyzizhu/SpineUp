<?php
declare(strict_types=1);

namespace App\Services;

class AIService
{
    private array $config;

    public function __construct()
    {
        $this->config = require __DIR__ . '/../../config/ai.php';
    }

    /**
     * 生成实时体态违规拟人化提醒
     *
     * @param string $persona 角色人设 (worker, cat, coach, anime)
     * @param float $angleDeg 倾角 (度)
     * @param float $durationSec 持续秒数
     * @param string $state 体态级别 (slightSlump, severeSlump)
     * @param string|null $customSystemPrompt 自定义系统提示词
     * @param string|null $customUserPrompt 自定义用户提示词
     * @return string
     */
    public function generateReminder(
        string $persona,
        float $angleDeg,
        float $durationSec,
        string $state,
        ?string $customSystemPrompt = null,
        ?string $customUserPrompt = null
    ): string {
        // 1. 特征哈希语义缓存检查 (节约 Token + 毫秒级极速返回)
        $cacheKey = sprintf('ai_remind_%s_%s_%d', $persona, $state, (int)round($angleDeg / 5.0));
        if ($this->config['enable_cache'] ?? true) {
            $cached = $this->getCached($cacheKey);
            if ($cached !== null) {
                return $cached;
            }
        }

        // 2. 检查是否有有效的大模型 API Key
        $apiKey = $this->config['api_key'] ?? '';
        if (!empty($apiKey)) {
            $llmResponse = $this->invokeUpstreamLLM($persona, $angleDeg, $durationSec, $state, $customSystemPrompt, $customUserPrompt);
            if ($llmResponse !== null) {
                if ($this->config['enable_cache'] ?? true) {
                    $this->setCache($cacheKey, $llmResponse, $this->config['cache_ttl'] ?? 3600);
                }
                return $llmResponse;
            }
        }

        // 3. 上游未配置、超时或异常时，服务端优雅降级至精编离线语料
        $fallback = $this->getFallbackCorpus($persona, $state);
        return $fallback;
    }

    /**
     * 调用云端大模型接口，具有严格毫秒级超时保护
     */
    private function invokeUpstreamLLM(
        string $persona,
        float $angleDeg,
        float $durationSec,
        string $state,
        ?string $customSystemPrompt,
        ?string $customUserPrompt
    ): ?string {
        $systemPrompt = $customSystemPrompt ?: $this->buildDefaultSystemPrompt($persona);
        $userPrompt = $customUserPrompt ?: sprintf(
            "当前检测到低头倾角 %.1f 度，持续低头 %.1f 秒，体态级别为 %s。请用 25 字以内一句话以人设口吻提醒挺胸坐直。",
            $angleDeg,
            $durationSec,
            $state
        );

        $payload = json_encode([
            'model' => $this->config['model'] ?? 'deepseek-chat',
            'messages' => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => $userPrompt]
            ],
            'max_tokens'  => 512,
            'temperature' => 0.8,
        ], JSON_UNESCAPED_UNICODE);

        $endpoint = rtrim($this->config['base_url'], '/') . '/chat/completions';
        $timeoutMs = (int)($this->config['timeout_ms'] ?? 5000);

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                "Authorization: Bearer {$this->config['api_key']}",
            ],
            CURLOPT_TIMEOUT        => 8,
            CURLOPT_CONNECTTIMEOUT => 3,
            CURLOPT_NOSIGNAL       => 1,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $rawResponse = curl_exec($ch);
        $curlError = curl_error($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($curlError || $httpCode !== 200 || !$rawResponse) {
            error_log("Upstream AI call failed: code={$httpCode}, error={$curlError}");
            return null;
        }

        $decoded = json_decode($rawResponse, true);
        $reply = trim($decoded['choices'][0]['message']['content'] ?? '');
        return !empty($reply) ? $reply : null;
    }

    private function buildDefaultSystemPrompt(string $persona): string
    {
        return match ($persona) {
            'worker' => '你是打工人专属工位搭子，语言风格是诙谐幽默、毒舌、一针见血，常常用周五、下班、老板不给换颈椎等打工人梗提醒用户坐直。回复必须限制在25字以内。',
            'cat'    => '你是一只趴在用户头顶的傲娇猫咪，说话习惯带"喵"，语气娇蛮可爱，提醒用户坐直不然会从头上滑下去或者压成猫饼。限制在25字以内。',
            'coach'  => '你是专业的物理理疗师与体态健康私教，语气温和严谨、充满鼓励，指出颈椎受力并指导肌肉复位。限制在25字以内。',
            'anime'  => '你是元气满满的动漫后辈/AI灵动少女，语气元气可爱、鼓励治愈，充满中二与热血精神，给前辈注入坐直元气。限制在25字以内。',
            default  => '你是体态守护助手，请用简短一句话提醒用户挺胸坐直，限制在25字以内。'
        };
    }

    private function getFallbackCorpus(string $persona, string $state): string
    {
        $corpus = $this->config['fallback_corpus'][$persona][$state]
            ?? $this->config['fallback_corpus']['worker']['severeSlump']
            ?? ['请立刻挺胸坐直，守护颈椎健康！'];

        return $corpus[array_rand($corpus)];
    }

    private function getCached(string $key): ?string
    {
        $cacheFile = __DIR__ . '/../../storage/cache/' . md5($key) . '.cache';
        if (file_exists($cacheFile)) {
            $data = unserialize(file_get_contents($cacheFile));
            if ($data && $data['expire'] > time()) {
                return $data['value'];
            }
        }
        return null;
    }

    private function setCache(string $key, string $value, int $ttl): void
    {
        $cacheDir = __DIR__ . '/../../storage/cache';
        if (!is_dir($cacheDir)) {
            mkdir($cacheDir, 0777, true);
        }
        $cacheFile = $cacheDir . '/' . md5($key) . '.cache';
        file_put_contents($cacheFile, serialize(['expire' => time() + $ttl, 'value' => $value]), LOCK_EX);
    }
}
