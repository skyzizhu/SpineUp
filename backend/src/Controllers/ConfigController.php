<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Common\Response;

class ConfigController
{
    /**
     * 远程配置与工效学参数下发
     * GET /v1/config/app
     */
    public function getAppConfig()
    {
        $appConfig = require __DIR__ . '/../../config/app.php';

        Response::json([
            'appName'                => 'SpineUp',
            'latestVersion'          => $appConfig['version'] ?? '1.0.0',
            'minSupportedVersion'    => '1.0.0',
            'forceUpdate'            => false,
            'slightSlumpThreshold'   => $appConfig['ergonomics']['slight_slump_threshold'] ?? 15.0,
            'severeSlumpThreshold'   => $appConfig['ergonomics']['severe_slump_threshold'] ?? 30.0,
            'aiGenerationTimeoutSec' => 2.5,
            'announcement'           => [
                'enabled' => false,
                'title'   => '',
                'content' => '',
            ]
        ]);
    }
}
