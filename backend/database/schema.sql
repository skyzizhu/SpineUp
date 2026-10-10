-- SpineUp (骨气) MySQL 5.7 / 8.0 数据库初始化建表脚本
-- 字符集: utf8mb4, 排序规则: utf8mb4_unicode_ci

CREATE DATABASE IF NOT EXISTS `spineup` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `spineup`;

-- 1. 用户主表 (支持 Apple 登录与匿名访客)
CREATE TABLE IF NOT EXISTS `su_users` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_uuid` CHAR(36) NOT NULL UNIQUE COMMENT '客户端业务唯一标识 UUID',
    `apple_user_id` VARCHAR(128) NULL UNIQUE COMMENT 'Apple 授权唯一标识',
    `is_guest` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否为匿名访客 1-是 0-否',
    `nickname` VARCHAR(64) NOT NULL DEFAULT 'SpineUp User',
    `streak_days` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '连续端坐打卡天数',
    `energy_coins` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '累计骨气能量币余额',
    `best_quality_ratio` DECIMAL(5,2) NOT NULL DEFAULT 100.00 COMMENT '最佳挺拔质量优秀率 (百分比 0-100)',
    `locale` VARCHAR(16) NOT NULL DEFAULT 'zh-Hans',
    `timezone` VARCHAR(32) NOT NULL DEFAULT 'Asia/Shanghai',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_apple_id` (`apple_user_id`),
    INDEX `idx_user_uuid` (`user_uuid`),
    INDEX `idx_energy_coins` (`energy_coins`),
    INDEX `idx_best_quality` (`best_quality_ratio`),
    INDEX `idx_streak_days` (`streak_days`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 设备绑定与偏好配置表 (支持 iPhone Duo 折叠双屏、耳机型号与零点校准)
CREATE TABLE IF NOT EXISTS `su_user_settings` (
    `user_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    `active_persona_id` VARCHAR(32) NOT NULL DEFAULT 'worker' COMMENT '激活的宠物: worker, cat, coach, anime',
    `calibration_base_pitch` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '俯仰基准零点',
    `calibration_base_roll` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '翻滚基准零点',
    `slight_slump_threshold` DOUBLE NOT NULL DEFAULT 15.0,
    `severe_slump_threshold` DOUBLE NOT NULL DEFAULT 30.0,
    `is_sound_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `is_haptic_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `is_voice_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `last_device_model` VARCHAR(64) NULL COMMENT '例如: iPhone Duo, iPhone 17 Pro',
    `headphone_model` VARCHAR(64) NULL COMMENT '例如: AirPods Pro 3',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_settings_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 每日姿态会话与工效学档案表 (每日汇总与多日历史)
CREATE TABLE IF NOT EXISTS `su_posture_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `session_date` DATE NOT NULL COMMENT '日期: YYYY-MM-DD',
    `upright_duration_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '良好端坐时长(秒)',
    `slump_duration_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '不良低头时长(秒)',
    `longest_streak_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '最长连续端坐时长(秒)',
    `accumulated_extra_load_kg` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '颈椎额外累积受力当量(kg)',
    `violations_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '低头违规次数',
    `score` INT NOT NULL DEFAULT 100 COMMENT '工效学健康分 0~100',
    `grade` CHAR(2) NOT NULL DEFAULT 'S' COMMENT '等级: S, A, B, C, D',
    `synced_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_user_date` (`user_id`, `session_date`),
    INDEX `idx_date_score` (`session_date`, `score`),
    CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 每日 AI 骨气病历档案表 (病历单与社交分享)
CREATE TABLE IF NOT EXISTS `su_daily_reports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `report_date` DATE NOT NULL,
    `persona_id` VARCHAR(32) NOT NULL,
    `diagnosis_title` VARCHAR(128) NOT NULL COMMENT '病历诊断称号，如: 阶段性打工低头综合征',
    `doctor_prescription` TEXT NOT NULL COMMENT '医生处方建议',
    `persona_comment` TEXT NOT NULL COMMENT '宠物拟人化犀利点评',
    `equivalent_item_name` VARCHAR(64) NOT NULL COMMENT '等效承重物品，如: 一头成年金毛寻回犬',
    `equivalent_item_kg` DOUBLE NOT NULL,
    `share_hash` CHAR(16) NOT NULL UNIQUE COMMENT '对外分享短链唯一识别码',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_user_report_date` (`user_id`, `report_date`),
    CONSTRAINT `fk_report_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 骨气能量与防作弊账本表 (Spine Energy Ledger)
CREATE TABLE IF NOT EXISTS `su_energy_ledger` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `delta_coins` INT NOT NULL COMMENT '变动能量币数量 (+/-)',
    `balance_after` INT UNSIGNED NOT NULL COMMENT '结算后总余额',
    `reason` VARCHAR(64) NOT NULL COMMENT '来源: UPRIGHT_TIME_SETTLE, STREAK_BONUS, OUTFIT_PURCHASE',
    `idempotent_key` VARCHAR(64) NOT NULL UNIQUE COMMENT '幂等去重键，防止前端网络重试导致多次累加',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_created` (`user_id`, `created_at`),
    CONSTRAINT `fk_ledger_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 客户端硬件与异常上报日志表 (耳机连接断开、崩溃、校准漂移)
CREATE TABLE IF NOT EXISTS `su_client_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NULL,
    `category` VARCHAR(32) NOT NULL COMMENT 'Motion, Headphone, Audio, DuoFold, Crash',
    `level` VARCHAR(16) NOT NULL DEFAULT 'WARNING' COMMENT 'INFO, WARNING, ERROR, CRITICAL',
    `message` VARCHAR(512) NOT NULL,
    `context_json` JSON NULL COMMENT '扩展上下文 (含倾角、设备型号、系统版本)',
    `client_time` DATETIME NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_category_level` (`category`, `level`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 30 秒办公室减负微操打卡记录表 (Relief Exercise Logs)
CREATE TABLE IF NOT EXISTS `su_relief_exercise_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `action_type` VARCHAR(32) NOT NULL DEFAULT 'CHIN_TUCK' COMMENT '动作类型: CHIN_TUCK (收下巴), W_STRETCH (W展肩), ERGONOMICS (工位优化)',
    `pitch_deg` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '完成时的低头角度',
    `extra_load_kg` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '完成时的额外负荷(kg)',
    `duration_sec` INT UNSIGNED NOT NULL DEFAULT 30 COMMENT '微操完成耗时(秒)',
    `reward_coins` INT UNSIGNED NOT NULL DEFAULT 5 COMMENT '获得的骨气能量币',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_action_time` (`user_id`, `created_at`),
    CONSTRAINT `fk_relief_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. AI 体态私教推演与急救处方日志表 (AI Consultation Logs)
CREATE TABLE IF NOT EXISTS `su_ai_consultation_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NULL,
    `request_type` VARCHAR(32) NOT NULL COMMENT 'HAZARD_PERSPECTIVE (危害透视), RELIEF_PRESCRIPTION (急救处方), REMINDER (实时提醒)',
    `persona_id` VARCHAR(32) NOT NULL DEFAULT 'worker',
    `context_pitch_deg` DOUBLE NOT NULL DEFAULT 0.0,
    `context_extra_load_kg` DOUBLE NOT NULL DEFAULT 0.0,
    `input_payload_json` JSON NULL COMMENT '传入给 AI 的完整传感器与会话上下文',
    `ai_response_json` JSON NULL COMMENT 'AI 输出的结构化结果',
    `model_name` VARCHAR(64) NOT NULL DEFAULT 'deepseek-chat',
    `tokens_used` INT UNSIGNED NOT NULL DEFAULT 0,
    `latency_ms` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_cached` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否命中缓存',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_created` (`user_id`, `created_at`),
    INDEX `idx_req_type` (`request_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. 全周期体态健康报告表 (支持日报/周报/月报/季报/年报的分级聚合与历史归档)
CREATE TABLE IF NOT EXISTS `su_periodic_reports` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `period_type` ENUM('weekly','monthly','quarterly','yearly') NOT NULL DEFAULT 'weekly' COMMENT '周期类型',
    `period_key` VARCHAR(32) NOT NULL COMMENT '周期标识如 2026-W41, 2026-10, 2026-Q4, 2026',
    `start_date` DATE NOT NULL COMMENT '周期开始日期',
    `end_date` DATE NOT NULL COMMENT '周期结束日期',
    `total_wear_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '有效监测总秒数',
    `upright_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '挺拔时长(秒)',
    `slump_sec` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '低头前倾时长(秒)',
    `avg_score` INT NOT NULL DEFAULT 85 COMMENT '平均健康评分',
    `accumulated_load_kg` DOUBLE NOT NULL DEFAULT 0.0 COMMENT '累计额外负荷(kg)',
    `alleviated_load_kg` DOUBLE NOT NULL DEFAULT 0.0 COMMENT 'SpineUp协助减负总量(kg)',
    `total_violations` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总违规报警次数',
    `best_day_date` DATE NULL DEFAULT NULL COMMENT '周内最佳挺拔日期',
    `fatigue_hotspot_hour` TINYINT DEFAULT 16 COMMENT '疲劳最高发小时(0-23)',
    `dowager_hump_risk` INT NOT NULL DEFAULT 15 COMMENT '富贵包风险指数(0-100)',
    `equivalent_item_name` VARCHAR(64) DEFAULT '约 3 辆金属山地自行车' COMMENT '趣味生活化等重比喻',
    `ai_persona_summary` TEXT COMMENT 'AI角色专属周期评价与建议',
    `share_hash` CHAR(16) NOT NULL DEFAULT '' COMMENT '16位分享短码',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_user_period` (`user_id`,`period_type`,`period_key`),
    INDEX `idx_user_dates` (`user_id`,`start_date`,`end_date`),
    INDEX `idx_share_hash` (`share_hash`),
    CONSTRAINT `fk_periodic_user` FOREIGN KEY (`user_id`) REFERENCES `su_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全周期体态健康报告表';
