<?php

/**
 * Configuration file
 */
include ("/app/config.inc.php");

/**
 * Process
 */
include ("/app/functions/functions.process.php");

$p = is_process_running();
if ($p)
{
        kill_process($p);
        end_process($p);
}
start_process("/app/admin/process.php /forms");


?>
