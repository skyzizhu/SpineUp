<?php
declare(strict_types=1);

namespace App\Common;

class Router
{
    /** @var array */
    private $routes = [];

    public function get(string $path, $handler, array $middlewares = [])
    {
        $this->addRoute('GET', $path, $handler, $middlewares);
    }

    public function post(string $path, $handler, array $middlewares = [])
    {
        $this->addRoute('POST', $path, $handler, $middlewares);
    }

    public function put(string $path, $handler, array $middlewares = [])
    {
        $this->addRoute('PUT', $path, $handler, $middlewares);
    }

    public function delete(string $path, $handler, array $middlewares = [])
    {
        $this->addRoute('DELETE', $path, $handler, $middlewares);
    }

    public function options(string $path, $handler)
    {
        $this->addRoute('OPTIONS', $path, $handler);
    }

    private function addRoute(string $method, string $path, $handler, array $middlewares = [])
    {
        $this->routes[] = [
            'method'      => $method,
            'path'        => rtrim($path, '/') ?: '/',
            'handler'     => $handler,
            'middlewares' => $middlewares,
        ];
    }

    public function dispatch()
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $uri = rtrim($uri, '/') ?: '/';

        // 自动兼容 Apache 二级子目录部署 (例如 /spineup/v1/... 或 /spineup/public/v1/...)
        if (($v1Pos = strpos($uri, '/v1/')) !== false) {
            $uri = substr($uri, $v1Pos);
        } elseif (($v1Pos = strpos($uri, '/v1')) !== false && strlen($uri) === $v1Pos + 3) {
            $uri = '/v1';
        }

        // 1. 全局 HTTP 安全响应头 (防 MIME 嗅探、防点击劫持、防 XSS 反弹)
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: SAMEORIGIN');
        header('X-XSS-Protection: 1; mode=block');
        header('Referrer-Policy: strict-origin-when-cross-origin');

        // 2. 空字节毒化截断攻击防御 (Null Byte Poisoning)
        $rawUri = $_SERVER['REQUEST_URI'] ?? '';
        if (strpos($rawUri, '%00') !== false || strpos($rawUri, "\0") !== false) {
            Response::error('Malicious request detected', 400, 400);
        }

        // 3. 报文体积防御：拒绝超过 2MB 的异常超大包 (防内存拒绝服务攻击)
        $contentLength = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
        if ($contentLength > 2097152) {
            Response::error('Request payload too large (Max 2MB)', 413, 413);
        }

        // 4. 统一处理 preflight OPTIONS 跨域预检
        if ($method === 'OPTIONS') {
            header('Access-Control-Allow-Origin: *');
            header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
            header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
            http_response_code(204);
            exit;
        }

        // 5. 执行全局风控与频率限制
        $rateLimiter = new \App\Middlewares\RateLimitMiddleware();
        $rateLimiter->handle();

        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }

            $pattern = preg_replace('#:([a-zA-Z0-9_]+)#', '(?P<$1>[^/]+)', $route['path']);
            $pattern = '#^' . $pattern . '$#';

            if (preg_match($pattern, $uri, $matches)) {
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);

                // 执行关联中间件
                foreach ($route['middlewares'] as $middleware) {
                    $mwInstance = new $middleware();
                    $mwInstance->handle();
                }

                // 执行控制器处理方法
                $handler = $route['handler'];
                if (is_array($handler)) {
                    list($class, $action) = $handler;
                    $controller = new $class();
                    $controller->$action($params);
                } elseif (is_callable($handler)) {
                    $handler($params);
                }
                return;
            }
        }

        // 404 未找到匹配路由
        Response::error("Endpoint not found: {$method} {$uri}", 404, 404);
    }
}
