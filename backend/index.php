<?php
declare(strict_types=1);

/**
 * 根目录转发入口：若 Apache 直接将根目录指向 backend，无缝转发至 public/index.php
 */

require_once __DIR__ . '/public/index.php';
