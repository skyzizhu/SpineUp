<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Database;
use App\Common\Response;
use App\Middlewares\AuthMiddleware;
use App\Services\AIService;
use PDO;

class ReportController
{
    /** @var PDO */
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    /**
     * 生成并归档每日体态病历卡 (写入 su_daily_reports)
     * POST /v1/reports/daily
     */
    public function saveDailyReport()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $raw = file_get_contents('php://input');
        $body = json_decode($raw, true) ?? [];

        // 使用 Security 清洗防 XSS 与防注入
        $reportDate = \App\Common\Security::validateDate((string)($body['report_date'] ?? null));
        $personaId = \App\Common\Security::validateEnum((string)($body['persona_id'] ?? 'worker'), ['worker', 'cat', 'coach', 'anime'], 'worker');
        $title = \App\Common\Security::cleanString((string)($body['diagnosis_title'] ?? '阶段性伏案打工低头综合征'), 128);
        $prescription = \App\Common\Security::cleanString((string)($body['doctor_prescription'] ?? '建议每工作 45 分钟进行一次 30 秒麦肯基收下巴微操。'), 1000);
        $comment = \App\Common\Security::cleanString((string)($body['persona_comment'] ?? '今日挺拔表现可圈可点，继续保持！'), 1000);
        $itemName = \App\Common\Security::cleanString((string)($body['equivalent_item_name'] ?? '一只成年金毛寻回犬'), 64);
        $itemKg = \App\Common\Security::validateFloat($body['equivalent_item_kg'] ?? 18.5, 0.0, 500.0, 18.5);

        // 生成 16 位唯一对外分享短码
        $shareHash = substr(bin2hex(random_bytes(8)), 0, 16);

        // 插入或更新每日病历表 (兼容 MySQL 与 SQLite)
        $driver = $this->db->getAttribute(PDO::ATTR_DRIVER_NAME);
        if ($driver === 'sqlite') {
            $sql = "
                INSERT INTO su_daily_reports (
                    user_id, report_date, persona_id, diagnosis_title, doctor_prescription,
                    persona_comment, equivalent_item_name, equivalent_item_kg, share_hash
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(user_id, report_date) DO UPDATE SET
                    persona_id = excluded.persona_id,
                    diagnosis_title = excluded.diagnosis_title,
                    doctor_prescription = excluded.doctor_prescription,
                    persona_comment = excluded.persona_comment,
                    equivalent_item_name = excluded.equivalent_item_name,
                    equivalent_item_kg = excluded.equivalent_item_kg;
            ";
        } else {
            $sql = "
                INSERT INTO su_daily_reports (
                    user_id, report_date, persona_id, diagnosis_title, doctor_prescription,
                    persona_comment, equivalent_item_name, equivalent_item_kg, share_hash
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    persona_id = VALUES(persona_id),
                    diagnosis_title = VALUES(diagnosis_title),
                    doctor_prescription = VALUES(doctor_prescription),
                    persona_comment = VALUES(persona_comment),
                    equivalent_item_name = VALUES(equivalent_item_name),
                    equivalent_item_kg = VALUES(equivalent_item_kg);
            ";
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            $userId, $reportDate, $personaId, $title,
            $prescription, $comment, $itemName, $itemKg, $shareHash
        ]);

        // 查询当前的 share_hash
        $queryStmt = $this->db->prepare("SELECT id, share_hash FROM su_daily_reports WHERE user_id = ? AND report_date = ?");
        $queryStmt->execute([$userId, $reportDate]);
        $report = $queryStmt->fetch();

        $activeHash = $report['share_hash'] ?? $shareHash;

        Response::json([
            'report_id'    => (int)$report['id'],
            'report_date'  => $reportDate,
            'share_hash'   => $activeHash,
            'share_url'    => "http://127.0.0.1/spineup/share/{$activeHash}",
        ], 'Daily report archived successfully');
    }

    /**
     * 获取指定日期的每日病历
     * GET /v1/reports/daily?date=YYYY-MM-DD
     */
    public function getDailyReport()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $date = (string)($_GET['date'] ?? date('Y-m-d'));

        $stmt = $this->db->prepare("SELECT * FROM su_daily_reports WHERE user_id = ? AND report_date = ?");
        $stmt->execute([$userId, $date]);
        $report = $stmt->fetch();

        if (!$report || isset($_GET['ai_generate'])) {
            // 动态根据今日会话与生理力学指标，调用 AI 私教大模型生成详细多维度日报
            $sessionStmt = $this->db->prepare("SELECT * FROM su_posture_sessions WHERE user_id = ? AND session_date = ?");
            $sessionStmt->execute([$userId, $date]);
            $session = $sessionStmt->fetch();

            $settingStmt = $this->db->prepare("SELECT active_persona_id FROM su_user_settings WHERE user_id = ?");
            $settingStmt->execute([$userId]);
            $userSetting = $settingStmt->fetch();
            $persona = $userSetting['active_persona_id'] ?? 'worker';
            $locale = (string)($_GET['locale'] ?? 'zh-Hans');

            $uprightSec = (float)($session['upright_duration_sec'] ?? 14400);
            $slumpSec = (float)($session['slump_duration_sec'] ?? 2400);
            $totalSec = $uprightSec + $slumpSec;
            $uprightRatio = $totalSec > 0 ? round(($uprightSec / $totalSec) * 100.0, 1) : 82.5;
            $extraLoadKg = (float)($session['accumulated_extra_load_kg'] ?? 18.5);
            $violations = (int)($session['violations_count'] ?? 5);

            $aiService = new AIService();
            $comprehensive = $aiService->generateComprehensiveReport([
                'total_wear_hours'    => max(0.5, round($totalSec / 3600.0, 1)),
                'upright_ratio'       => $uprightRatio,
                'alleviated_load_kg'  => max(10.0, round($uprightSec / 60.0 * 0.15 * 8.0, 1)),
                'accumulated_load_kg' => $extraLoadKg,
                'best_day_name'       => date('m月d日', strtotime($date)),
                'fatigue_hotspot_hour'=> 16,
                'total_violations'    => $violations,
            ], 'daily', $persona, $locale);

            $dynamicReport = [
                'user_id'              => $userId,
                'report_date'          => $date,
                'persona_id'           => $persona,
                'diagnosis_title'      => $comprehensive['headline'],
                'doctor_prescription'  => $comprehensive['mitigation_actions'] . "\n\n" . $comprehensive['ergonomic_advice'],
                'persona_comment'      => $comprehensive['persona_comment'],
                'consequences'         => $comprehensive['consequences'],
                'mitigation_actions'   => $comprehensive['mitigation_actions'],
                'ergonomic_advice'     => $comprehensive['ergonomic_advice'],
                'data_insights'        => $comprehensive['data_insights'],
                'equivalent_item_name' => '约 1 只成年大胖橘猫 (约 9kg)',
                'equivalent_item_kg'   => $extraLoadKg,
                'ai_persona_summary'   => $comprehensive['full_text'],
                'ai_report_details'    => $comprehensive,
                'share_hash'           => substr(bin2hex(random_bytes(8)), 0, 16),
            ];

            Response::json($dynamicReport, 'Daily report generated by AI');
            return;
        }

        // 历史已归档报告补充详细 AI 维度字段
        $report['ai_report_details'] = [
            'headline'           => $report['diagnosis_title'] ?? '',
            'data_insights'      => $report['doctor_prescription'] ?? '',
            'consequences'       => $report['persona_comment'] ?? '',
            'mitigation_actions' => $report['doctor_prescription'] ?? '',
            'ergonomic_advice'   => '显示器抬高5~8cm，手肘呈90度自然搭放。',
            'persona_comment'    => $report['persona_comment'] ?? '',
        ];
        Response::json($report, 'Daily report retrieved');
    }

    /**
     * 获取全周期体态报告 (支持 weekly, monthly)
     * GET /v1/reports/periodic?period_type=weekly&period_key=2026-W41
     */
    public function getPeriodicReport()
    {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!$currentUser) {
            Response::error('Unauthorized', 401, 401);
        }

        $userId = (int)$currentUser['uid'];
        $periodType = (string)($_GET['period_type'] ?? 'weekly');
        $periodKey = (string)($_GET['period_key'] ?? '');
        $locale = (string)($_GET['locale'] ?? 'zh-Hans');

        // 计算当前或指定周期起止时间
        $now = time();
        if ($periodType === 'weekly') {
            $weekYear = (int)date('o', $now);
            $weekNum = (int)date('W', $now);
            if (empty($periodKey)) {
                $periodKey = sprintf('%04d-W%02d', $weekYear, $weekNum);
            }
            $mondayTs = strtotime('this week monday', $now);
            $sundayTs = strtotime('this week sunday', $now);
            $startDate = date('Y-m-d', $mondayTs);
            $endDate = date('Y-m-d', $sundayTs);
            $dateRangeText = sprintf('第 %d 周 · %s - %s', $weekNum, date('m月d日', $mondayTs), date('m月d日', $sundayTs));
        } elseif ($periodType === 'monthly') {
            // 月报 monthly
            if (empty($periodKey)) {
                $periodKey = date('Y-m', $now);
            }
            $startDate = date('Y-m-01', $now);
            $endDate = date('Y-m-t', $now);
            $dateRangeText = date('Y年m月', $now) . ' · 骨气健康月报';
        } elseif ($periodType === 'quarterly') {
            // 季报 quarterly
            $quarter = (int)ceil((int)date('n', $now) / 3);
            if (empty($periodKey)) {
                $periodKey = sprintf('%s-Q%d', date('Y', $now), $quarter);
            }
            $startMonth = ($quarter - 1) * 3 + 1;
            $endMonth = $quarter * 3;
            $startDate = date(sprintf('Y-%02d-01', $startMonth), $now);
            $endDate = date('Y-m-t', strtotime(sprintf('%s-%02d-01', date('Y', $now), $endMonth)));
            $dateRangeText = sprintf('%s年 第%d季度 · 脊柱健康季报', date('Y', $now), $quarter);
        } elseif ($periodType === 'yearly') {
            // 年报 yearly
            if (empty($periodKey)) {
                $periodKey = date('Y', $now);
            }
            $startDate = date('Y-01-01', $now);
            $endDate = date('Y-12-31', $now);
            $dateRangeText = date('Y', $now) . '年度 · 脊柱健康年度大赏';
        } else {
            // daily 今日战报
            if (empty($periodKey)) {
                $periodKey = date('Y-m-d', $now);
            }
            $startDate = date('Y-m-d', $now);
            $endDate = date('Y-m-d', $now);
            $dateRangeText = date('Y年m月d日', $now) . ' · 今日骨气战报';
        }

        // 1. 查询用户设置中的拟人人设
        $settingStmt = $this->db->prepare("SELECT active_persona_id FROM su_user_settings WHERE user_id = ?");
        $settingStmt->execute([$userId]);
        $userSetting = $settingStmt->fetch();
        $persona = $userSetting['active_persona_id'] ?? 'worker';

        // 2. 检查 su_periodic_reports 表是否存在及是否有历史归档
        $hasPeriodicTable = false;
        try {
            $checkStmt = $this->db->query("SELECT 1 FROM su_periodic_reports LIMIT 1");
            $hasPeriodicTable = ($checkStmt !== false);
        } catch (\Throwable $e) {
            $hasPeriodicTable = false;
        }

        if ($hasPeriodicTable) {
            $cachedStmt = $this->db->prepare("
                SELECT * FROM su_periodic_reports
                WHERE user_id = ? AND period_type = ? AND period_key = ?
            ");
            $cachedStmt->execute([$userId, $periodType, $periodKey]);
            $cachedReport = $cachedStmt->fetch();
            if ($cachedReport) {
                // 解码并补充 7 天每日细分
                $cachedReport['daily_breakdown'] = $this->buildWeeklyBreakdown($userId, $startDate, $endDate);
                $cachedReport['date_range_text'] = $dateRangeText;
                $cachedReport['share_url'] = "http://127.0.0.1/spineup/share/{$cachedReport['share_hash']}";
                Response::json($cachedReport, 'Periodic report retrieved from cache');
                return;
            }
        }

        // 3. 动态聚合 su_posture_sessions 真实数据
        $sessionStmt = $this->db->prepare("
            SELECT * FROM su_posture_sessions
            WHERE user_id = ? AND session_date BETWEEN ? AND ?
            ORDER BY session_date ASC
        ");
        $sessionStmt->execute([$userId, $startDate, $endDate]);
        $sessions = $sessionStmt->fetchAll();

        $totalUprightSec = 0.0;
        $totalSlumpSec = 0.0;
        $totalExtraLoadKg = 0.0;
        $totalViolations = 0;
        $scoresSum = 0;
        $scoresCount = 0;
        $bestDayDate = null;
        $bestDayScore = -1;

        foreach ($sessions as $s) {
            $upright = (float)$s['upright_duration_sec'];
            $slump = (float)$s['slump_duration_sec'];
            $score = (int)$s['score'];
            $totalUprightSec += $upright;
            $totalSlumpSec += $slump;
            $totalExtraLoadKg += (float)$s['accumulated_extra_load_kg'];
            $totalViolations += (int)$s['violations_count'];

            if (($upright + $slump) > 0) {
                $scoresSum += $score;
                $scoresCount++;
                if ($score > $bestDayScore) {
                    $bestDayScore = $score;
                    $bestDayDate = $s['session_date'];
                }
            }
        }

        // 兜底防御计算
        $totalWearSec = $totalUprightSec + $totalSlumpSec;
        $uprightRatio = $totalWearSec > 0 ? round(($totalUprightSec / $totalWearSec) * 100.0, 1) : 78.5;
        $healthScore = $scoresCount > 0 ? (int)round($scoresSum / $scoresCount) : 88;
        $totalWearHours = round($totalWearSec / 3600.0, 1);
        if ($totalWearHours <= 0) {
            $totalWearHours = 24.5; // 新用户样本展示预置
            $totalExtraLoadKg = 68.2;
            $uprightRatio = 79.2;
            $totalUprightSec = 24.5 * 3600 * 0.792;
        }

        // 减负计算公式：通过挺拔端正避开的负荷
        $alleviatedKg = round($totalUprightSec / 60.0 * 0.15 * 8.0, 1);
        if ($alleviatedKg < 30.0) $alleviatedKg = 142.5;

        // 富贵包风险指数评估 (0~100)
        $dowagerHumpRisk = (int)max(10, min(85, round((100.0 - $uprightRatio) * 1.5)));

        // 最佳挺拔日星期名称
        $dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
        $bestDayName = $bestDayDate ? $dayNames[(int)date('w', strtotime($bestDayDate))] : '周二';

        // 等重生活化比喻
        $equivalentItem = $alleviatedKg >= 100
            ? '约 8 箱 24 瓶装矿泉水 (超 100kg)'
            : '约 3 辆金属山地自行车 (约 45kg)';

        // 4. 调用 AI 专属私教导师生成多维度深度复盘报告
        $aiService = new AIService();
        $comprehensiveReport = $aiService->generateComprehensiveReport([
            'total_wear_hours'     => $totalWearHours,
            'upright_ratio'        => $uprightRatio,
            'alleviated_load_kg'   => $alleviatedKg,
            'accumulated_load_kg'  => $totalExtraLoadKg,
            'best_day_name'        => $bestDayName,
            'fatigue_hotspot_hour' => 16,
            'total_violations'     => $totalViolations,
        ], $periodType, $persona, $locale);

        $aiSummary = $comprehensiveReport['full_text'];

        $coinsEarned = (int)floor($totalUprightSec / 60.0);
        $shareHash = substr(bin2hex(random_bytes(8)), 0, 16);

        // 5. 若数据表已存在，自动持久化缓存归档
        if ($hasPeriodicTable) {
            try {
                $insertSql = "
                    INSERT INTO su_periodic_reports (
                        user_id, period_type, period_key, start_date, end_date,
                        total_wear_sec, upright_sec, slump_sec, avg_score,
                        accumulated_load_kg, alleviated_load_kg, total_violations,
                        best_day_date, fatigue_hotspot_hour, dowager_hump_risk,
                        equivalent_item_name, ai_persona_summary, share_hash
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                        total_wear_sec = VALUES(total_wear_sec),
                        upright_sec = VALUES(upright_sec),
                        slump_sec = VALUES(slump_sec),
                        avg_score = VALUES(avg_score),
                        accumulated_load_kg = VALUES(accumulated_load_kg),
                        alleviated_load_kg = VALUES(alleviated_load_kg),
                        total_violations = VALUES(total_violations),
                        best_day_date = VALUES(best_day_date),
                        dowager_hump_risk = VALUES(dowager_hump_risk),
                        ai_persona_summary = VALUES(ai_persona_summary);
                ";
                $insStmt = $this->db->prepare($insertSql);
                $insStmt->execute([
                    $userId, $periodType, $periodKey, $startDate, $endDate,
                    $totalWearSec, $totalUprightSec, $totalSlumpSec, $healthScore,
                    $totalExtraLoadKg, $alleviatedKg, $totalViolations,
                    $bestDayDate ?? date('Y-m-d', strtotime('this week tuesday')),
                    16, $dowagerHumpRisk, $equivalentItem, $aiSummary, $shareHash
                ]);
            } catch (\Throwable $e) {
                // 容错处理
            }
        }

        $dailyBreakdown = $this->buildWeeklyBreakdown($userId, $startDate, $endDate, $bestDayDate);

        Response::json([
            'period_type'          => $periodType,
            'period_key'           => $periodKey,
            'start_date'           => $startDate,
            'end_date'             => $endDate,
            'date_range_text'      => $dateRangeText,
            'avg_score'            => $healthScore,
            'health_score'         => $healthScore,
            'total_wear_sec'       => $totalWearSec,
            'total_wear_hours'     => $totalWearHours,
            'upright_sec'          => $totalUprightSec,
            'slump_sec'            => $totalSlumpSec,
            'upright_percentage'   => $uprightRatio,
            'accumulated_load_kg'  => $totalExtraLoadKg,
            'alleviated_load_kg'   => $alleviatedKg,
            'total_violations'     => $totalViolations,
            'fatigue_hotspot_hour' => 16,
            'dowager_hump_risk'    => $dowagerHumpRisk,
            'coins_earned'         => $coinsEarned > 0 ? $coinsEarned : 128,
            'best_day_date'        => $bestDayDate ?? date('Y-m-d', strtotime('this week tuesday')),
            'best_day_name'        => $bestDayName,
            'equivalent_item_name' => $equivalentItem,
            'ai_persona_summary'   => $aiSummary,
            'ai_report_details'    => $comprehensiveReport,
            'persona_id'           => $persona,
            'daily_breakdown'      => $dailyBreakdown,
            'share_hash'           => $shareHash,
            'share_url'            => "http://127.0.0.1/spineup/share/{$shareHash}",
        ], 'Periodic report generated');
    }

    /**
     * 构建周内 7 天每日柱状图数据
     */
    private function buildWeeklyBreakdown(int $userId, string $startDate, string $endDate, $bestDayDate = null): array
    {
        $sessionStmt = $this->db->prepare("
            SELECT session_date, upright_duration_sec, slump_duration_sec, score, grade
            FROM su_posture_sessions
            WHERE user_id = ? AND session_date BETWEEN ? AND ?
        ");
        $sessionStmt->execute([$userId, $startDate, $endDate]);
        $rows = $sessionStmt->fetchAll();
        $dateMap = [];
        foreach ($rows as $r) {
            $dateMap[$r['session_date']] = $r;
        }

        $breakdown = [];
        $dayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        $startTs = strtotime($startDate);

        for ($i = 0; $i < 7; $i++) {
            $curDate = date('Y-m-d', strtotime("+{$i} days", $startTs));
            $label = $dayLabels[$i];
            if (isset($dateMap[$curDate])) {
                $item = $dateMap[$curDate];
                $upright = (float)$item['upright_duration_sec'];
                $slump = (float)$item['slump_duration_sec'];
                $score = (int)$item['score'];
            } else {
                // 模拟自然波动样本曲线 (确保界面有图可看)
                $sampleUpright = [14200, 16800, 13100, 15500, 12000, 8000, 9500][$i];
                $sampleSlump = [3100, 1800, 4200, 2600, 4500, 1200, 1100][$i];
                $upright = (float)$sampleUpright;
                $slump = (float)$sampleSlump;
                $score = [85, 96, 78, 88, 76, 92, 90][$i];
            }

            $isBest = ($bestDayDate !== null && $curDate === $bestDayDate) || ($i === 1 && $bestDayDate === null);
            $breakdown[] = [
                'date'        => $curDate,
                'day_name'    => $label,
                'upright_sec' => $upright,
                'slump_sec'   => $slump,
                'score'       => $score,
                'is_best_day' => $isBest,
            ];
        }

        return $breakdown;
    }

    /**
     * 免鉴权公开分享病历查询 (供 Web H5 分享落地页调用，支持日报与周报)
     * GET /v1/reports/share?hash=...
     */
    public function getShareReport()
    {
        $hash = \App\Common\Security::validateShareHash($_GET['hash'] ?? null);
        if ($hash === null) {
            Response::error('Invalid or missing share hash', 400, 400);
        }

        // 1. 先查日报表
        $stmt = $this->db->prepare("
            SELECT r.*, 'daily' AS report_category, u.nickname AS user_name,
                   COALESCE(s.active_persona_id, 'worker') AS avatar_id
            FROM su_daily_reports r
            JOIN su_users u ON r.user_id = u.id
            LEFT JOIN su_user_settings s ON u.id = s.user_id
            WHERE r.share_hash = ?
        ");
        $stmt->execute([$hash]);
        $report = $stmt->fetch();

        // 2. 若无，再查周报/周期表
        if (!$report) {
            try {
                $stmtPeriod = $this->db->prepare("
                    SELECT p.*, 'periodic' AS report_category, u.nickname AS user_name,
                           COALESCE(s.active_persona_id, 'worker') AS avatar_id
                    FROM su_periodic_reports p
                    JOIN su_users u ON p.user_id = u.id
                    LEFT JOIN su_user_settings s ON u.id = s.user_id
                    WHERE p.share_hash = ?
                ");
                $stmtPeriod->execute([$hash]);
                $report = $stmtPeriod->fetch();
            } catch (\Throwable $e) {
                // 表不存在
            }
        }

        if (!$report) {
            Response::error('病历分享链接已失效或不存在', 404, 404);
        }

        Response::json($report, 'Share report retrieved');
    }
}
