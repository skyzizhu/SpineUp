# SpineUp (骨气) 后端 API 服务

> 基于 **Apache + MySQL 8.0 + PHP 8.1+** 架构的高可用 RESTful 微服务。  
> 专为 **SpineUp iOS App** (iOS 26+ / iPhone Duo / AirPods 空间姿态监测) 提供后端支撑。

---

## 目录结构

```text
backend/
├── config/                  # 应用、数据库与 AI 配置
│   ├── app.php              # 全局配置、JWT 密钥、工效学默认阈值
│   ├── database.php         # MySQL PDO 连接配置 (含 SQLite 本地降级开发模式)
│   └── ai.php               # 上游大模型 API Key 配置、1500ms 超时熔断与拟人化语料库
├── database/
│   └── schema.sql           # MySQL 8.0 完整建表 DDL (InnoDB / utf8mb4)
├── public/                  # Apache DocumentRoot 入口目录
│   ├── .htaccess            # mod_rewrite 统一伪静态路由
│   └── index.php            # 单一入口分发器
├── src/                     # PSR-4 核心源码 (App\ 命名空间)
│   ├── Common/              # Database 单例、JWT 编解码、Response 统一输出、RESTful Router
│   ├── Controllers/         # AuthController, AIController, ConfigController
│   ├── Middlewares/         # AuthMiddleware (Bearer JWT 校验)
│   └── Services/            # AIService (cURL 1.5s 极速超时熔断与特征哈希语义缓存)
├── storage/                 # 运行时缓存与日志目录
└── test_api.php             # 核心模块自动化自检脚本
```

---

## 快速上手与运行

### 1. 导入 MySQL 数据库

在 MySQL 中执行初始化脚本：

```bash
mysql -u root -p < database/schema.sql
```

或通过 phpMyAdmin 导入 `database/schema.sql`。

### 2. 配置 Apache 虚拟主机

将 Apache 的 `DocumentRoot` 指向 `backend/public` 目录，并确保开启 `mod_rewrite` 模块：

```apache
<VirtualHost *:80>
    ServerName api.spineup.local
    DocumentRoot "/path/to/anyway/backend/public"
    
    <Directory "/path/to/anyway/backend/public">
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

或使用 PHP 内置服务器进行即时本地调试：

```bash
php -S 127.0.0.1:8080 -t backend/public
```

### 3. 配置云端大模型 (可选)

在 `backend/config/ai.php` 或环境变量中填入你的 API Key (例如 DeepSeek / OpenAI)：
```php
'api_key'  => 'sk-xxxxxxxx',
'base_url' => 'https://api.deepseek.com/v1',
'model'    => 'deepseek-chat',
```
*注：即使未填写 API Key，系统内置的 4 角色拟人化语料库与特征哈希缓存也会以 **0~2ms** 的极速自动兜底响应，确保 iOS 客户端永远稳定不超时。*

### 4. 运行接口自检

```bash
php backend/test_api.php
```

---

## 核心接口契约速览

| 请求方法 | 路由地址 | 说明 | 鉴权方式 |
| :--- | :--- | :--- | :--- |
| `POST` | `/v1/auth/guest` | 匿名访客一键登录/秒开 | 公开 |
| `GET` | `/v1/users/me` | 获取当前用户信息与偏好 | Bearer JWT |
| `PUT` | `/v1/users/settings` | 云端同步坐姿校准零点基准与阈值 | Bearer JWT |
| `POST` | `/v1/ai/reminder` | **体态违规拟人化实时提醒** (对接 `SUCloudAIEngine.swift`) | 公开/JWT |
| `GET` | `/v1/config/app` | 远程配置下发 (工效学阈值/公告/版本) | 公开 |
