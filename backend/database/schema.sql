-- SpineUp (骨气) MySQL 8.0 数据库初始化建表脚本
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
    `locale` VARCHAR(16) NOT NULL DEFAULT 'zh-Hans',
    `timezone` VARCHAR(32) NOT NULL DEFAULT 'Asia/Shanghai',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_apple_id` (`apple_user_id`),
    INDEX `idx_user_uuid` (`user_uuid`)
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
