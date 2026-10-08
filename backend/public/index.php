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
use App\Middlewares\AuthMiddleware;

$router = new Router();

// ==================== 1. 认证与用户管理 ====================
$router->post('/v1/auth/guest', [AuthController::class, 'guest']);
$router->get('/v1/users/me', [AuthController::class, 'me'], [AuthMiddleware::class]);
$router->put('/v1/users/settings', [AuthController::class, 'updateSettings'], [AuthMiddleware::class]);

// ==================== 2. AI 大模型网关 (对接 iOS SUCloudAIEngine) ====================
$router->post('/v1/ai/reminder', [AIController::class, 'reminder']);

// ==================== 3. 姿态会话同步 ====================
$router->post('/v1/sessions/sync', [SessionController::class, 'sync'], [AuthMiddleware::class]);

// ==================== 4. 远程配置中心 ====================
$router->get('/v1/config/app', [ConfigController::class, 'getAppConfig']);

// 执行分发
$router->dispatch();
