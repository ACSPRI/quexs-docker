#!/bin/bash
set -eu

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	file_env 'QUEXS_DB_HOST' 'mysql'
    file_env 'QUEXS_PATH' "\/"
    file_env 'QUEXS_PORT' ""
    file_env 'QUEXS_ADMIN_PASSWORD' ""
	# if we're linked to MySQL and thus have credentials already, let's use them
	file_env 'QUEXS_DB_USER' "${MYSQL_ENV_MYSQL_USER:-root}"
	if [ "$QUEXS_DB_USER" = 'root' ]; then
		file_env 'QUEXS_DB_PASSWORD' "${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}"
	else
		file_env 'QUEXS_DB_PASSWORD' "${MYSQL_ENV_MYSQL_PASSWORD:-}"
	fi
	file_env 'QUEXS_DB_NAME' "${MYSQL_ENV_MYSQL_DATABASE:-quexs}"
	if [ -z "$QUEXS_DB_PASSWORD" ]; then
		echo >&2 'error: missing required QUEXS_DB_PASSWORD environment variable'
		echo >&2 '  Did you forget to -e QUEXS_DB_PASSWORD=... ?'
		echo >&2
		echo >&2 '  (Also of interest might be QUEXS_DB_USER and QUEXS_DB_NAME.)'
		exit 1
	fi

	if ! [ -e index.php ]; then
		echo >&2 "queXS not found in $(pwd) - copying now..."
		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi
		bzr export . /usr/src/quexs
		echo >&2 "Complete! queXS has been successfully copied to $(pwd)"
	else
        echo >&2 "queXS found in $(pwd) - not copying."
	fi

    chown www-data:www-data -R /var/www/html/include/limesurvey/tmp 
    chown www-data:www-data -R /var/www/html/include/limesurvey/upload 


	if [ ! -e config.inc.local.php ]; then
	    cp config.inc.local.php.example config.inc.local.php
    fi

	# see http://stackoverflow.com/a/2705678/433558
	sed_escape_lhs() {
		echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
	}
	sed_escape_rhs() {
		echo "$@" | sed -e 's/[\/&]/\\&/g'
	}
	php_escape() {
		php -r 'var_export(('$2') $argv[1]);' -- "$1"
	}
	set_config() {
		key="$1"
		value="$2"
		sed -i "/$key/s/'[^']*'/'$value'/2" config.inc.local.php
	}

	set_config 'DB_HOST' "$QUEXS_DB_HOST"
	set_config 'DB_USER' "$QUEXS_DB_USER"
	set_config 'DB_PASS' "$QUEXS_DB_PASSWORD"
	set_config 'DB_NAME' "$QUEXS_DB_NAME"
	set_config 'QUEXS_PATH' "$QUEXS_PATH"
    set_config 'QUEXS_PORT' "$QUEXS_PORT"

	file_env 'QUEXS_DEBUG'
	if [ "$QUEXS_DEBUG" ]; then
		set_config 'DEBUG' 1 
	fi

	if [ "$QUEXS_ADMIN_PASSWORD" ]; then
		QUEXS_ADMIN_PASSWORD=`printf $QUEXS_ADMIN_PASSWORD | sha256sum | awk '{ print $1 }'`
	fi

	TERM=dumb php -- "$QUEXS_DB_HOST" "$QUEXS_DB_USER" "$QUEXS_DB_PASSWORD" "$QUEXS_DB_NAME" "$QUEXS_ADMIN_PASSWORD" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

$stderr = fopen('php://stderr', 'w');

list($host, $socket) = explode(':', $argv[1], 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}

$maxTries = 10;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

// check if database populated

if (!$mysql->query('SELECT COUNT(*) AS C FROM ' . $mysql->real_escape_string($argv[4]) . '.outcome')) {
    fwrite($stderr, "\n" . 'Cannot find queXS database. Will now populate... ' . $mysql->error . "\n");

    $command = 'mysql'
        . ' --host=' . $host
        . ' --user=' . $argv[2]
        . ' --password=' . $argv[3]
        . ' --database=' . $argv[4]
        . ' --execute="SOURCE ';

    fwrite($stderr, "\n" . 'Loading queXS database...' . "\n");
    $output1 = shell_exec($command . '/var/www/html/database/quexs.sql"');
    fwrite($stderr, "\n" . 'Loaded queXS database: ' . $output1 . "\n");
    fwrite($stderr, "\n" . 'Loading queXS US customisations...' . "\n");
    $output2 = shell_exec($command . '/var/www/html/database/queXS_US.sql"');
    fwrite($stderr, "\n" . 'Loaded queXS US customisations: ' . $output2 . "\n");

} else {
	fwrite($stderr, "\n" . 'queXS Database found. Leaving unchanged.' . "\n");
}

if (!empty($argv[5])) {
    if ($mysql->query('UPDATE ' . $mysql->real_escape_string($argv[4]) . '.users SET password = \'' . $mysql->real_escape_string($argv[5]) . '\' WHERE uid = 1')) {
	    fwrite($stderr, "\n" . 'Updated queXS admin password.' . "\n");
	} else {
	    fwrite($stderr, "\n" . 'Failed to update admin password.' .  "\n");
	}
}

$mysql->close();
EOPHP

#Run system sort processes

su -s /bin/bash -c "php /var/www/html/voip/startvoipprocess.php" www-data &

fi

exec "$@"
