<?php

define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_HOST', 'localhost');
define('DB_NAME', 'quexf');

define('ADODB_DIR', '/usr/share/php/adodb/');

define('BLANK_PAGE_DETECTION', true);

define('PROCESS_MISSING_PAGES',true);

//REQUIRED: Ghostscript binary
define('GS_BIN', "/usr/bin/gs");

//Temporary directory
define('TEMPORARY_DIRECTORY', "/tmp");

define('IMAGES_IN_DATABASE', false);
define('IMAGES_DIRECTORY','/images/');
define('OCR_ENABLED',true);

//Do not remove the following line:
include(dirname(__FILE__) . '/config.default.php');
?>
