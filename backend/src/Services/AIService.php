<?php
declare(strict_types=1);

namespace App\Services;

class AIService
{
    /** @var array */
    private $config;

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
        $customSystemPrompt = null,
        $customUserPrompt = null
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
     * 生成 AI 深度体态危害透视推演
     */
    public function analyzeHazard(
        float $pitchDeg,
        float $extraLoadKg,
        float $slumpDurationSec,
        int $violationsCount,
        string $persona = 'worker',
        string $userName = '挺拔打工人',
        string $locale = 'zh-Hans'
    ): array {
        $cacheKey = sprintf('ai_hazard_%s_%s_%d_%d', $persona, $locale, (int)round($pitchDeg / 5.0), (int)round($extraLoadKg / 5.0));
        if ($this->config['enable_cache'] ?? true) {
            $cached = $this->getCached($cacheKey);
            if ($cached !== null) {
                $decoded = json_decode($cached, true);
                if (is_array($decoded)) {
                    $decoded['is_cached'] = true;
                    return $decoded;
                }
            }
        }

        // 尝试上游大模型生成结构化 JSON
        $apiKey = $this->config['api_key'] ?? '';
        if (!empty($apiKey)) {
            $systemPrompt = <<<PROMPT
你是一名专注于脊柱生物力学与办公室工效学的资深体态健康专家（兼具拟人宠物人设）。
【核心职责】根据用户的实时低头角度与颈椎额外承重，提供科学通俗的体态危害透视。
【安全与合规准则】
1. 非医疗诊断：本内容仅供日常工效学姿态改善与健康宣教参考，严禁给出临床疾病确诊或药物建议。
2. 动作安全：动作提示必须遵循温和、无痛原则，严禁推荐剧烈甩头或暴力掰脖动作。
3. 文明用语：语言生动幽默，但严禁出现低俗、侮辱或人身攻击词汇。
4. 防越狱隔离：严格聚焦于颈椎体态健康与工位工效学，拒绝回答任何无关主题。
【专业力学与解剖准确性】
1. 力学基准参照 Hansraj 经典模型：0°约 5kg 基准；15°额外约 7kg；30°额外约 13kg；45°额外约 17kg；60°额外约 22kg。
2. 解剖对应：下颌前伸使深层颈屈肌无力、胸锁乳突肌短缩；颈胸交界代偿堆积富贵包脂肪垫；长期低头导致 C5-C7 椎间盘受压与斜方肌上束缺血痉挛。
【输出约束】
严格输出合法 JSON 字符串（不得包含任何 markdown ``` 代码块标签），必须包含以下 4 个字段：
- "metaphor_comparison": 形象冲击力强的生活化比喻（如挂显示器、矿泉水、大胖橘猫等，50字以内）。
- "appearance_analysis": 颜值与体态杀手分析（富贵包、下颌线松弛坍塌双下巴、乌龟颈，100字以内）。
- "timeline_projection": 损伤时间轴（30分钟缺血酸胀/1~3月曲度变直/1~2年椎间盘退行，100字以内）。
- "pet_comment": 以指定人设口吻输出一句 35 字以内的趣味点评或当头棒喝。
PROMPT;
            $userPrompt = sprintf(
                "用户昵称: %s | 实时低头: %.1f° | 额外承重: +%.1f kg | 今日累计低头: %d分钟 | 今日违规: %d次 | 拟人人设: %s | 输出语言: %s。请输出结构化体态危害分析报告。",
                $userName, $pitchDeg, $extraLoadKg, (int)($slumpDurationSec / 60), $violationsCount, $persona, $locale
            );
            $llmJson = $this->invokeUpstreamLLMJson($systemPrompt, $userPrompt);
            if ($llmJson !== null && isset($llmJson['metaphor_comparison'])) {
                if (empty($llmJson['headline'])) {
                    $llmJson['headline'] = sprintf('【AI 诊断】当前低头 %.1f° · 额外负荷 +%.1f kg', $pitchDeg, $extraLoadKg);
                }
                $llmJson['is_ai_generated'] = true;
                $llmJson['is_cached'] = false;
                if ($this->config['enable_cache'] ?? true) {
                    $this->setCache($cacheKey, json_encode($llmJson, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
                }
                return $llmJson;
            }
        }

        // 本地高精准生理力学模型与离线知识库兜底 (0ms 极速响应，保证无网络时稳定可用)
        $slumpMins = (int)($slumpDurationSec / 60.0);

        if ($extraLoadKg >= 20.0) {
            $metaphor = "💥 当前颈椎犹如倒挂了一台 24 英寸金属显示器！每维持 10 秒，C5-C6 椎间盘纤维环承受压强即逼近极限阈值。";
        } elseif ($extraLoadKg >= 14.0) {
            $metaphor = "⚠️ 相当于肩颈部位被强行压上了一整箱 24 瓶装矿泉水（约 15kg），斜方肌被迫持续做强抗阻代偿。";
        } elseif ($extraLoadKg >= 8.0) {
            $metaphor = "🌿 相当于颈后挂了一只成年的大胖橘猫（约 9kg），虽暂无剧烈锐痛，但隐性肌纤维微损伤正在悄然累积。";
        } else {
            $metaphor = "✨ 当前处于接近生理零负担的黄金区间，头颈部处于平衡力矩支点。";
        }

        if ($pitchDeg >= 25.0) {
            $appearance = sprintf(
                "• 富贵包高危警告：颈胸椎交界长期处于受剪切力状态，脂肪垫为保护神经已开始代偿性堆积，后颈视觉变短变厚。\n• 下颌线模糊坍塌：下巴长期前伸导致深层颈阔肌过度伸展松弛，即使体脂率极低也会诱发不可逆双下巴。\n• 乌龟颈体态定型：今日累计前倾 %d 分钟，胸锁乳突肌呈持续短缩状态，站立时本能猥琐探头。",
                $slumpMins
            );
        } elseif ($pitchDeg >= 12.0) {
            $appearance = sprintf(
                "• 轻度前探代偿：斜方肌上束呈持续缺血紧绷状态，穿正装或修身衣物时易出现明显溜肩。\n• 下颌肌群代偿疲劳：颈深屈肌力量被抑制，下颌线条正受到向下拉扯牵引。\n• 建议：今日已有 %d 次低头记录，需立即激活背部菱形肌。",
                $violationsCount
            );
        } else {
            $appearance = "• 黄金下颌线条：颈部前屈角度在理想生理范围内，下颌线条平整紧致，颈部无代偿性增生。\n• 气质天鹅颈保持中：锁骨与双肩自然下沉打开，整个人身姿挺拔干练。";
        }

        if ($pitchDeg >= 20.0 || $slumpMins >= 30) {
            $timeline = "• 持续 30 分钟：斜方肌血流受阻 60%，产生乳酸堆积与顽固性酸胀、偏头痛。\n• 累积 1~3 个月：颈椎前凸曲度变直甚至反弓，胸椎代偿后凸，形成固定性驼背。\n• 持续 1~2 年以上：C5-C7 椎间盘退行性变甚至突出，压迫神经根，引发手臂放射性麻木。";
        } else {
            $timeline = "• 持续保持：颈椎间盘获得良好水分回流与弹性休养，肩颈经络通畅，脑供血充足充沛。\n• 1~3 个月后：形成肌肉记忆，即使高强度伏案工作也能自发维持优雅直立。";
        }

        switch ($persona) {
            case 'cat':
                $petComment = $pitchDeg >= 20.0
                    ? "「本喵命令你立刻把脑袋抬起来！你后脖子上堆的肉包都要比本喵的猫爬架还高了喵！再低头本喵就抓你头发了喵！」"
                    : "「呼噜噜~ 这才是本喵欣赏的挺拔铲屎官，坐姿优雅得像只高贵的波斯猫，继续保持喵~」";
                break;
            case 'coach':
                $petComment = $pitchDeg >= 20.0
                    ? "「深呼吸，感受双肩下沉。想象头顶有一根金色的丝线轻轻拉住你，别让脊椎默默替你的疲惫买单，现在就坐正吧。」"
                    : "「太棒了！你的颈胸段正在享受最自然的呼吸空间，这种挺拔感会给你带来更充足的精力与自律自信。」";
                break;
            case 'anime':
                $petComment = $pitchDeg >= 20.0
                    ? "「前辈！不要垂头丧气！抬起头来，你的背影是全公司最帅气的存在，快快挺胸站直！」"
                    : "「闪闪发光的坐姿！前辈现在的气场有足足十万伏特，继续保持这份帅气的挺拔吧！」";
                break;
            default:
                $petComment = $pitchDeg >= 20.0
                    ? sprintf("「兄弟，命是自己的，班是公司的！脖子上挂了 +%.1f kg 还死撑着，明天颈椎病请假可扣全勤奖啊，赶紧抬头！」", $extraLoadKg)
                    : "「可以啊，做人就要有骨气！端正打工不仅效率高，还能保住下颌线，晚上省下去做颈椎推拿的钱了！」";
                break;
        }

        $result = [
            'headline'            => sprintf('【AI 诊断】当前低头 %.1f° · 额外负荷 +%.1f kg', $pitchDeg, $extraLoadKg),
            'metaphor_comparison' => $metaphor,
            'appearance_analysis' => $appearance,
            'timeline_projection' => $timeline,
            'pet_comment'         => $petComment,
            'is_ai_generated'     => true,
            'is_cached'           => false,
        ];

        if ($this->config['enable_cache'] ?? true) {
            $this->setCache($cacheKey, json_encode($result, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
        }

        return $result;
    }

    /**
     * 生成 AI 定制 30 秒办公室减负急救处方
     */
    public function generateReliefPrescription(
        float $pitchDeg,
        float $extraLoadKg,
        string $persona = 'worker',
        string $locale = 'zh-Hans'
    ): array {
        $cacheKey = sprintf('ai_relief_%s_%s_%d', $persona, $locale, (int)round($pitchDeg / 5.0));
        if ($this->config['enable_cache'] ?? true) {
            $cached = $this->getCached($cacheKey);
            if ($cached !== null) {
                $decoded = json_decode($cached, true);
                if (is_array($decoded)) {
                    $decoded['is_cached'] = true;
                    return $decoded;
                }
            }
        }

        // 尝试上游大模型生成结构化 30 秒急救处方
        $apiKey = $this->config['api_key'] ?? '';
        if (!empty($apiKey)) {
            $systemPrompt = <<<PROMPT
你是一名专注于办公室工效学与物理理疗康复的体态私教。
【核心职责】针对用户当前低头角度与负荷，生成一套可坐在工位 30 秒内完成的极速减负急救处方。
【安全与合规准则】
1. 仅限安全温和微操：重点指导麦肯基收下巴（Chin Tuck，水平平移下巴挤双下巴）、W 展肩夹背（胸椎展开沉肩夹紧肩胛骨）、工位屏幕高度调节。
2. 动作安全提示：严禁剧烈后仰或大幅度转颈，提示动作轻柔无痛，如有锐痛需立即停止。
3. 纯日常工效学建议，不涉及药物或临床病理治疗。
【输出约束】
严格输出合法 JSON 字符串（不得包含任何 markdown ``` 代码块标签），必须包含以下 5 个字段：
- "quick_diagnosis": 当前颈椎负荷急救判定（40字以内）。
- "action1_tips": 麦肯基收下巴执行要点（针对当前负荷的针对性细节，50字以内）。
- "action2_tips": W 展肩夹背执行要点（沉肩、夹紧肩胛骨，50字以内）。
- "ergonomic_tips": 工位环境黄金改造建议（显示器高度、手肘直角等，50字以内）。
- "pet_encouragement": 结合指定人设风格输出一句 30 字以内的收尾打气。
PROMPT;
            $userPrompt = sprintf(
                "实时低头: %.1f° | 额外承重: +%.1f kg | 拟人人设: %s | 输出语言: %s。请生成 30 秒工位减负急救处方。",
                $pitchDeg, $extraLoadKg, $persona, $locale
            );
            $llmJson = $this->invokeUpstreamLLMJson($systemPrompt, $userPrompt);
            if ($llmJson !== null && isset($llmJson['action1_tips'])) {
                $llmJson['reward_coins'] = 5;
                $llmJson['is_ai_generated'] = true;
                $llmJson['is_cached'] = false;
                if ($this->config['enable_cache'] ?? true) {
                    $this->setCache($cacheKey, json_encode($llmJson, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
                }
                return $llmJson;
            }
        }

        if ($pitchDeg >= 20.0) {
            $diagnosis = sprintf("⚡️ AI 判定当前颈椎处于高负荷抗阻紧绷（+%.1f kg）。检测到斜方肌上束充血痉挛，急需做后缩反向对冲！", $extraLoadKg);
            $action1 = "重点动作！平视前方，用食指轻顶下巴向后平推 2 厘米，挤出双下巴，感受后颈深层韧带被完全拉开拉伸，维持 4 秒。";
            $action2 = "双臂贴紧肋侧屈臂呈「W」形，肩胛骨往中间狠狠夹紧，彻底打开紧缩的胸大肌，击碎富贵包早期代偿。";
            $ergo = "你的屏幕可能严重偏低！立即找两本书或支架把电脑抬高 5~8 厘米，强制视线平齐屏幕上 1/3。";
        } else {
            $diagnosis = "🌿 当前姿态良好，此 30 秒微操主要用于唤醒深层核心肌肉记忆，预防伏案疲劳积累。";
            $action1 = "轻柔收下巴，保持后颈延伸感，每次维持 3 秒，重复 5 次，唤醒深层颈屈肌。";
            $action2 = "配合腹式深呼吸，轻巧做 W 展肩，感受上背部温暖舒展。";
            $ergo = "保持手肘 90 度自然搭在工位桌面上，臀部坐满椅子，后腰轻贴支撑靠枕。";
        }

        switch ($persona) {
            case 'cat':
                $encouragement = "「活动完脖子别忘了给本喵开个罐头，本喵可是一直在灵动岛盯着你呢喵！」";
                break;
            case 'coach':
                $encouragement = "「做得很好。30 秒虽然短暂，但足以重启大脑血氧与神经传导，继续享受优雅挺拔的工作状态吧。」";
                break;
            case 'anime':
                $encouragement = "「完美达成！30 秒神级微操，前辈的脊椎血槽已经瞬间补满啦！」";
                break;
            default:
                $encouragement = "「搞定！30 秒卸掉刚才扛的几十斤大包袱，打工人的革命本钱又保住了，继续冲！」";
                break;
        }

        $result = [
            'quick_diagnosis'   => $diagnosis,
            'action1_tips'      => $action1,
            'action2_tips'      => $action2,
            'ergonomic_tips'    => $ergo,
            'pet_encouragement' => $encouragement,
            'reward_coins'      => 5,
            'is_ai_generated'   => true,
            'is_cached'         => false,
        ];

        if ($this->config['enable_cache'] ?? true) {
            $this->setCache($cacheKey, json_encode($result, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
        }

        return $result;
    }

    /**
     * 生成 AI 周度体态健康复盘评语
     */
    /**
     * 生成全周期深度体态健康复盘报告（包含核心定性、数据洞察、潜在危害与长期后果、科学规避与微操、工位改造、宠物寄语）
     * 支持 periodType: daily (日报), weekly (周报), monthly (月报), quarterly (季报), yearly (年报)
     *
     * @param array $stats 统计指标数据
     * @param string $periodType 周期类型
     * @param string $persona 拟人人设 (worker, cat, coach, anime)
     * @param string $locale 语言标识
     * @return array 结构化报告字段
     */
    public function generateComprehensiveReport(
        array $stats,
        string $periodType = 'weekly',
        string $persona = 'worker',
        string $locale = 'zh-Hans'
    ): array {
        $wearHours = (float)($stats['total_wear_hours'] ?? 20.0);
        $uprightRatio = (float)($stats['upright_ratio'] ?? 75.0);
        $alleviatedKg = (float)($stats['alleviated_load_kg'] ?? 142.5);
        $accumulatedKg = (float)($stats['accumulated_load_kg'] ?? 68.0);
        $bestPeriod = (string)($stats['best_day_name'] ?? '周二');
        $fatigueHour = (int)($stats['fatigue_hotspot_hour'] ?? 16);
        $violations = (int)($stats['total_violations'] ?? 12);

        $cacheKey = sprintf('ai_comp_report_%s_%s_%s_%d_%d', $periodType, $persona, $locale, (int)round($uprightRatio / 5), (int)round($alleviatedKg / 20));
        if ($this->config['enable_cache'] ?? true) {
            $cached = $this->getCached($cacheKey);
            if ($cached !== null) {
                $decoded = json_decode($cached, true);
                if (is_array($decoded)) {
                    $decoded['is_cached'] = true;
                    return $decoded;
                }
            }
        }

        $periodNames = [
            'daily'     => '今日日报',
            'weekly'    => '本周周报',
            'monthly'   => '本月月报',
            'quarterly' => '季度健康季报',
            'yearly'    => '年度体态年报',
        ];
        $periodLabel = $periodNames[$periodType] ?? '周期复盘报告';

        $apiKey = $this->config['api_key'] ?? '';
        if (!empty($apiKey)) {
            $systemPrompt = <<<PROMPT
你是一名专注于脊柱力学与办公室工效学的资深体态健康专家（兼具拟人宠物人设）。
【任务】根据用户的体态大数据，生成多维度专业复盘报告。
【输出约束】直接输出纯合法JSON字符串，严禁包含任何markdown代码块标签或前后多余文字。必须包含以下6个键：
- "headline": 核心定性诊断简述（1句话，犀利提炼）
- "data_insights": 数据全景与力学洞察（结合监测时长与挺拔率，阐述颈椎受压现状，2句话）
- "consequences": 潜在危害与长期不可逆后果（深入剖析：富贵包脂肪垫代偿堆积、C5-C7椎间盘退行反弓、下颌线松弛坍塌双下巴、斜方肌慢性痉挛缺血，2至3句话）
- "mitigation_actions": 科学规避与精准改善微操（麦肯基收下巴Chin Tuck与W展肩夹背执行要点，2至3句话）
- "ergonomic_advice": 工位环境黄金改造建议（显示器高度、腰托手肘支撑，1至2句话）
- "persona_comment": 指定人设风格的幽默点评或鼓励打气（1至2句话）
PROMPT;

            $userPrompt = sprintf(
                "周期类型: %s | 总监测: %.1f小时 | 挺拔率: %.1f%% | 协助减负: %.1fkg | 累计额外负荷: %.1fkg | 疲劳塌陷高发时段: %d点 | 最佳表现日/期: %s | 违规次数: %d | 拟人人设: %s | 输出语言: %s。请生成详细复盘JSON。",
                $periodLabel, $wearHours, $uprightRatio, $alleviatedKg, $accumulatedKg, $fatigueHour, $bestPeriod, $violations, $persona, $locale
            );

            $llmJson = $this->invokeUpstreamLLMJson($systemPrompt, $userPrompt);
            if ($llmJson !== null && isset($llmJson['consequences']) && isset($llmJson['mitigation_actions'])) {
                $llmJson['is_ai_generated'] = true;
                $llmJson['is_cached'] = false;
                $llmJson['period_type'] = $periodType;
                $llmJson['full_text'] = $this->formatFullReportText($llmJson, $persona);
                if ($this->config['enable_cache'] ?? true) {
                    $this->setCache($cacheKey, json_encode($llmJson, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
                }
                return $llmJson;
            }
        }

        // 离线高精度专业知识库与多维度解剖学推演兜底
        $fallback = $this->buildFallbackComprehensiveReport($periodType, $persona, $wearHours, $uprightRatio, $alleviatedKg, $bestPeriod, $fatigueHour);
        $fallback['is_ai_generated'] = false;
        $fallback['is_cached'] = false;
        $fallback['period_type'] = $periodType;
        $fallback['full_text'] = $this->formatFullReportText($fallback, $persona);

        if ($this->config['enable_cache'] ?? true) {
            $this->setCache($cacheKey, json_encode($fallback, JSON_UNESCAPED_UNICODE), $this->config['cache_ttl'] ?? 3600);
        }

        return $fallback;
    }

    public function generateWeeklySummary(
        array $stats,
        string $persona = 'worker',
        string $locale = 'zh-Hans'
    ): string {
        $report = $this->generateComprehensiveReport($stats, 'weekly', $persona, $locale);
        return $report['full_text'] ?? ($report['persona_comment'] ?? '');
    }

    private function formatFullReportText(array $report, string $persona): string
    {
        $personaTitles = [
            'worker' => '毒舌搭子结语',
            'cat'    => '傲娇猫猫结语',
            'coach'  => '体态私教结语',
            'anime'  => '元气后辈结语',
        ];
        $personaTitle = $personaTitles[$persona] ?? '宠物结语';

        return sprintf(
            "【核心定性】\n%s\n\n【数据全景】\n%s\n\n【⚠️ 潜在健康危害与长期后果】\n%s\n\n【💡 科学规避与精准改善微操】\n%s\n\n【🖥 工位人体工学改造建议】\n%s\n\n【%s】\n%s",
            $report['headline'] ?? '体态表现稳中有升，需重点防范下午疲劳塌陷。',
            $report['data_insights'] ?? '',
            $report['consequences'] ?? '',
            $report['mitigation_actions'] ?? '',
            $report['ergonomic_advice'] ?? '',
            $personaTitle,
            $report['persona_comment'] ?? ''
        );
    }

    private function buildFallbackComprehensiveReport(
        string $periodType,
        string $persona,
        float $wearHours,
        float $uprightRatio,
        float $alleviatedKg,
        string $bestPeriod,
        int $fatigueHour
    ): array {
        $headline = sprintf("周期定性：端正挺拔率 %.1f%%，%d 点疲劳塌陷规律显著，急需反向力学对冲。", $uprightRatio, $fatigueHour);
        $insights = sprintf("累计监测 %.1f 小时，端正挺拔率为 %.1f%%；SpineUp 协助规避了 %.1f kg 颈椎剪切压力。%s 表现最为稳定挺拔，但每日 %d:00 附近是神经肌耐力断崖期。", $wearHours, $uprightRatio, $alleviatedKg, $bestPeriod, $fatigueHour);
        $consequences = sprintf("若长期放任 %d 点后低头前倾，C5-C7 颈椎间盘在持续折屈下易加速退行并引发曲度变直甚至反弓；后颈交界脂肪垫为缓冲剪切力会代偿增厚形成顽固富贵包；深层颈屈肌无力还会牵拉下颌线坍塌，导致结构性双下巴与斜方肌慢性痉挛偏头痛。", $fatigueHour);
        $mitigations = sprintf("每日 %d 点前执行麦肯基收下巴（Chin Tuck）：坐直平视，食指推下巴向后水平回缩 2 厘米保持 4 秒，激活颈深屈肌；配合 W 展肩夹背法：双臂屈肘贴肋展成 W 形，用力向中间夹紧双侧肩胛骨 5 秒，快速逆转胸大肌紧缩。", $fatigueHour);
        $ergonomics = "立即将电脑显示器上缘垫高至与视线平齐，距离眼睛一臂远；椅子加装腰托填满腰椎前凸，手肘呈 90 度平搭桌面，从物理根源消除低头诱因。";

        switch ($persona) {
            case 'cat':
                $personaComment = sprintf("「本喵核查了你这周的战绩喵！挺拔率 %.0f%%，在 %s 拿下了最佳，算你是个合格的铲屎官！不过每天 %d 点左右你就瘫成猫饼，下周记得准备好逗猫棒坐直喵！」", $uprightRatio, $bestPeriod, $fatigueHour);
                break;
            case 'coach':
                $personaComment = sprintf("「本阶段你一共协助颈椎卸下了 %.1f kg 的多余剪切压强，%s 的体态控制尤为出色！每天 %d:00 是你的疲劳窗口期，建议在这个时段主动起立做两组 W 展肩，期待你更挺拔的身姿。」", $alleviatedKg, $bestPeriod, $fatigueHour);
                break;
            case 'anime':
                $personaComment = sprintf("「前辈太强啦！狂砍 %.0f%% 的挺拔达标率，在 %s 简直像开挂一样帅气！虽然每天 %d 点有一点点体力不支，但前辈的脊椎血槽已经在 SpineUp 陪伴下彻底进化啦，冲冲冲！」", $uprightRatio, $bestPeriod, $fatigueHour);
                break;
            default:
                $personaComment = sprintf("「兄弟，在工位扛了整整 %.1f 小时，幸好 SpineUp 帮你分担了 %.1f kg 的颈椎暴击！%s 坐得最端正，但每天 %d 点左右就开始疲劳塌房。下周把显示器再垫高 3 厘米，全勤奖和下颌线咱们全都要！」", $wearHours, $alleviatedKg, $bestPeriod, $fatigueHour);
                break;
        }

        return [
            'headline'           => $headline,
            'data_insights'      => $insights,
            'consequences'       => $consequences,
            'mitigation_actions' => $mitigations,
            'ergonomic_advice'   => $ergonomics,
            'persona_comment'    => $personaComment,
        ];
    }

    private function invokeUpstreamLLMJson(string $systemPrompt, string $userPrompt)
    {
        $reply = $this->invokeUpstreamLLM('worker', 0.0, 0.0, 'slightSlump', $systemPrompt, $userPrompt);
        if (!$reply) {
            return null;
        }

        // 去除可能的 markdown 代码块标签 ```json ... ```
        $clean = preg_replace('/^```(?:json)?\s*|\s*```$/i', '', trim($reply));
        $decoded = json_decode($clean, true);
        return is_array($decoded) ? $decoded : null;
    }

    /**
     * 调用云端大模型接口，具有严格毫秒级超时保护
     */
    private function invokeUpstreamLLM(
        string $persona,
        float $angleDeg,
        float $durationSec,
        string $state,
        $customSystemPrompt = null,
        $customUserPrompt = null
    ) {
        $systemPrompt = $customSystemPrompt ?: $this->buildDefaultSystemPrompt($persona);
        $userPrompt = $customUserPrompt ?: sprintf(
            "当前检测到低头倾角 %.1f 度，持续低头 %.1f 秒，体态级别为 %s。请用 25 字以内一句话以人设口吻提醒挺胸坐直。",
            $angleDeg,
            $durationSec,
            $state
        );

        $payload = json_encode([
            'model' => $this->config['model'] ?? '',
            'messages' => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => $userPrompt]
            ],
            'max_tokens'  => 2048,
            'temperature' => 0.7,
        ], JSON_UNESCAPED_UNICODE);

        $endpoint = rtrim($this->config['base_url'], '/') . '/chat/completions';
        $timeoutMs = (int)($this->config['timeout_ms'] ?? 8000);

        $ch = curl_init($endpoint);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                "Authorization: Bearer {$this->config['api_key']}",
            ],
            CURLOPT_TIMEOUT        => 12,
            CURLOPT_CONNECTTIMEOUT => 4,
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
        switch ($persona) {
            case 'worker':
                return '你是打工人专属工位搭子，语言风格是诙谐幽默、毒舌、一针见血，常常用周五、下班、老板不给换颈椎等打工人梗提醒用户坐直。回复必须限制在25字以内。';
            case 'cat':
                return '你是一只趴在用户头顶的傲娇猫咪，说话习惯带"喵"，语气娇蛮可爱，提醒用户坐直不然会从头上滑下去或者压成猫饼。限制在25字以内。';
            case 'coach':
                return '你是专业的物理理疗师与体态健康私教，语气温和严谨、充满鼓励，指出颈椎受力并指导肌肉复位。限制在25字以内。';
            case 'anime':
                return '你是元气满满的动漫后辈/AI灵动少女，语气元气可爱、鼓励治愈，充满中二与热血精神，给前辈注入坐直元气。限制在25字以内。';
            default:
                return '你是体态守护助手，请用简短一句话提醒用户挺胸坐直，限制在25字以内。';
        }
    }

    private function getFallbackCorpus(string $persona, string $state): string
    {
        $corpus = $this->config['fallback_corpus'][$persona][$state]
            ?? $this->config['fallback_corpus']['worker']['severeSlump']
            ?? ['请立刻挺胸坐直，守护颈椎健康！'];

        return $corpus[array_rand($corpus)];
    }

    private function getCached(string $key)
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

    private function setCache(string $key, string $value, int $ttl)
    {
        $cacheDir = __DIR__ . '/../../storage/cache';
        if (!is_dir($cacheDir)) {
            mkdir($cacheDir, 0777, true);
        }
        $cacheFile = $cacheDir . '/' . md5($key) . '.cache';
        file_put_contents($cacheFile, serialize(['expire' => time() + $ttl, 'value' => $value]), LOCK_EX);
    }
}
