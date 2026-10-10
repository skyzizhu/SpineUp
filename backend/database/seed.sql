-- SpineUp 骨气能量社群初始数据种子脚本 (21位多样化人格与榜单用户)
USE `spineup`;

INSERT INTO `su_users` (`id`, `user_uuid`, `is_guest`, `nickname`, `streak_days`, `energy_coins`, `best_quality_ratio`, `locale`) VALUES
(1, "unit-test-d0210df8", 1, "挺拔打工人阿强", 7, 450, 86.5, "zh-Hans"),
(2, "unit-test-f562d5d9", 1, "低头族觉醒者", 6, 380, 84, "zh-Hans"),
(3, "unit-test-f5f56ce3", 1, "背背佳退役选手", 9, 520, 89, "zh-Hans"),
(4, "unit-test-faa5945c", 1, "工位普拉提琳琳", 11, 680, 91.5, "zh-Hans"),
(5, "user-a-2ed370", 1, "天鹅颈阿珍", 25, 1200, 96.5, "zh-Hans"),
(6, "user-b-f77329", 1, "傲娇体态大师", 14, 855, 88, "zh-Hans"),
(7, "unit-test-f7947600", 1, "端坐码字小陈", 5, 310, 83, "zh-Hans"),
(8, "user-a-3936a5", 1, "天鹅颈阿珍", 25, 1200, 96.5, "zh-Hans"),
(9, "user-b-bded1c", 1, "傲娇体态大师", 14, 855, 88, "zh-Hans"),
(10, "cloud-cat-mia", 0, "云端天鹅颈·米娅", 28, 1480, 98.5, "zh-Hans"),
(11, "geek-afei", 0, "不低头的极客阿飞", 21, 1320, 95, "zh-Hans"),
(12, "zen-master-zhang", 0, "禅意挺拔大师老张", 30, 1650, 99, "zh-Hans"),
(13, "yoga-teacher-lin", 0, "瑜伽课代表林老师", 19, 1190, 94.2, "zh-Hans"),
(14, "medic-zhou", 0, "严厉骨科周医生", 26, 1420, 97.5, "zh-Hans"),
(15, "daming-worker", 0, "告别富贵包的大明", 14, 950, 92, "zh-Hans"),
(16, "punk-lin", 0, "朋克正坐小林", 15, 890, 91, "zh-Hans"),
(17, "nuomi-cat", 0, "专注备考的糯米", 12, 810, 89.5, "zh-Hans"),
(18, "morning-run-kai", 0, "晨跑挺拔达人小凯", 10, 680, 88, "zh-Hans"),
(19, "anan-worker", 0, "端坐写报告的安安", 7, 540, 85.5, "zh-Hans"),
(20, "airpods-haozi", 0, "AirPods守护者浩子", 5, 410, 83, "zh-Hans"),
(21, "xixi-coach", 0, "拒绝圆肩的茜茜", 4, 280, 80.5, "zh-Hans")
ON DUPLICATE KEY UPDATE nickname=VALUES(nickname), energy_coins=VALUES(energy_coins), streak_days=VALUES(streak_days), best_quality_ratio=VALUES(best_quality_ratio);

INSERT INTO `su_user_settings` (`user_id`, `active_persona_id`) VALUES
(1, "worker"),
(2, "worker"),
(3, "worker"),
(4, "worker"),
(7, "worker"),
(10, "cat"),
(11, "worker"),
(12, "zen"),
(13, "coach"),
(14, "medic"),
(15, "worker"),
(16, "rebel"),
(17, "cat"),
(18, "coach"),
(19, "worker"),
(20, "cat"),
(21, "coach")
ON DUPLICATE KEY UPDATE active_persona_id=VALUES(active_persona_id);
