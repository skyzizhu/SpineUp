<?php
declare(strict_types=1);

/**
 * SpineUp (骨气) 后端统一 RESTful 入口文件
 */

require_once __DIR__ . '/../autoload.php';

use App\Common\Router;
use App\Controllers\AuthController;
use App\Controllers\AIController;
use App\Controllers\ConfigController;
use App\Controllers\SessionController;
use App\Controllers\LeaderboardController;
use App\Controllers\ReliefController;
use App\Controllers\LogController;
use App\Controllers\ReportController;
use App\Middlewares\AuthMiddleware;

$router = new Router();

// ==================== 1. 认证与用户管理 ====================
$router->post('/v1/auth/guest', [AuthController::class, 'guest']);
$router->get('/v1/users/me', [AuthController::class, 'me'], [AuthMiddleware::class]);
$router->put('/v1/users/settings', [AuthController::class, 'updateSettings'], [AuthMiddleware::class]);
$router->put('/v1/users/profile', [LeaderboardController::class, 'updateProfile'], [AuthMiddleware::class]);

// ==================== 2. AI 大模型体态私教网关 ====================
$router->post('/v1/ai/reminder', [AIController::class, 'reminder']);
$router->post('/v1/ai/posture-hazard', [AIController::class, 'postureHazard']);
$router->post('/v1/ai/relief-prescription', [AIController::class, 'reliefPrescription']);

// ==================== 3. 骨气榜 (正向激励排行榜) ====================
$router->get('/v1/leaderboard', [LeaderboardController::class, 'getLeaderboard']);

// ==================== 4. 30 秒急救减负微操打卡领能量 ====================
$router->post('/v1/relief/claim', [ReliefController::class, 'claim'], [AuthMiddleware::class]);

// ==================== 5. 全周期体态报告归档与社交分享 (日报/周报/月报) ====================
$router->post('/v1/reports/daily', [ReportController::class, 'saveDailyReport'], [AuthMiddleware::class]);
$router->get('/v1/reports/daily', [ReportController::class, 'getDailyReport'], [AuthMiddleware::class]);
$router->get('/v1/reports/periodic', [ReportController::class, 'getPeriodicReport'], [AuthMiddleware::class]);
$router->get('/v1/reports/share', [ReportController::class, 'getShareReport']);

// ==================== 6. 客户端硬件与异常埋点上报 (写入 su_client_logs) ====================
$router->post('/v1/logs/client', [LogController::class, 'uploadClientLogs']);

// ==================== 7. 姿态会话同步与历史回溯 ====================
$router->post('/v1/sessions/sync', [SessionController::class, 'sync'], [AuthMiddleware::class]);
$router->get('/v1/sessions/history', [SessionController::class, 'history'], [AuthMiddleware::class]);

// ==================== 8. 远程配置中心 ====================
$router->get('/v1/config/app', [ConfigController::class, 'getAppConfig']);

// 执行分发
$router->dispatch();
