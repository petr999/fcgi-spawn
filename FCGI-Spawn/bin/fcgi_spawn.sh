#!/bin/sh

. /etc/rc.subr

name="fcgi_spawn"
rcvar=${name}_enable

fcgi_spawn_enable=${fcgi_spawn_enable:-"NO"}
pidfile=${fcgi_spawn_pid:-"/var/run/${name}.pid"}

load_rc_config ${name}

fcgi_spawn_config_path=${fcgi_spawn_config_path:-"/usr/local/etc/${name}"}
fcgi_spawn_log=${fcgi_spawn_log:-"/var/log/${name}.log"}
fcgi_spawn_socket_path=${fcgi_spawn_socket_path:-"/tmp/spawner.sock"}
fcgi_spawn_redefine_exit=${fcgi_spawn_redefine_exit:-"0"}
fcgi_spawn_username=${fcgi_spawn_username:-"fcgi"}
fcgi_spawn_groupname=${fcgi_spawn_groupname:-"fcgi"}
fcgi_spawn_flags=${fcgi_spawn_flags:-""}
command="/var/www/alfacomp/wg/bin/${name}"
command_args="-l ${fcgi_spawn_log} -p ${pidfile} -c ${fcgi_spawn_config_path} -u ${fcgi_spawn_username} -g ${fcgi_spawn_groupname}  -s ${fcgi_spawn_socket_path}"
required_dirs=${fcgi_spawn_config_path}

run_rc_command "$1"
