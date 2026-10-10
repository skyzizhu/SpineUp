-- ============================================================
-- SpineUp (骨气) 全周期体态健康报告表
-- 支持日报/周报/月报/季报/年报的分级聚合与历史归档
-- ============================================================

CREATE TABLE IF NOT EXISTS `su_periodic_reports` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `period_type` enum('weekly','monthly','quarterly','yearly') NOT NULL DEFAULT 'weekly' COMMENT '周期类型',
  `period_key` varchar(32) NOT NULL COMMENT '周期标识如 2026-W41, 2026-10, 2026-Q4, 2026',
  `start_date` date NOT NULL COMMENT '周期开始日期',
  `end_date` date NOT NULL COMMENT '周期结束日期',
  `total_wear_sec` double NOT NULL DEFAULT '0' COMMENT '有效监测总秒数',
  `upright_sec` double NOT NULL DEFAULT '0' COMMENT '挺拔时长(秒)',
  `slump_sec` double NOT NULL DEFAULT '0' COMMENT '低头前倾时长(秒)',
  `avg_score` int(11) NOT NULL DEFAULT '85' COMMENT '平均健康评分',
  `accumulated_load_kg` double NOT NULL DEFAULT '0' COMMENT '累计额外负荷(kg)',
  `alleviated_load_kg` double NOT NULL DEFAULT '0' COMMENT 'SpineUp协助减负总量(kg)',
  `total_violations` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '总违规报警次数',
  `best_day_date` date DEFAULT NULL COMMENT '周内最佳挺拔日期',
  `fatigue_hotspot_hour` tinyint(4) DEFAULT '16' COMMENT '疲劳最高发小时(0-23)',
  `dowager_hump_risk` int(11) NOT NULL DEFAULT '15' COMMENT '富贵包风险指数(0-100)',
  `equivalent_item_name` varchar(64) DEFAULT '约 3 辆金属山地自行车' COMMENT '趣味生活化等重比喻',
  `ai_persona_summary` text COMMENT 'AI角色专属周期评价与建议',
  `share_hash` char(16) NOT NULL DEFAULT '' COMMENT '16位分享短码',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_period` (`user_id`,`period_type`,`period_key`),
  KEY `idx_user_dates` (`user_id`,`start_date`,`end_date`),
  KEY `idx_share_hash` (`share_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全周期体态健康报告表';
