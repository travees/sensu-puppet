# = Class: sensu::redis::config
#
# Sets the Sensu redis config
#
class sensu::redis::config {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $sensu::purge_config and !$sensu::server and !$sensu::api {
    $ensure = 'absent'
  } else {
    $ensure = 'present'
  }

  file { "${sensu::etc_dir}/conf.d/redis.json":
    ensure => $ensure,
    owner  => $sensu::user,
    group  => $sensu::group,
    mode   => $sensu::file_mode,
  }

  sensu_redis_config { $::fqdn:
    ensure             => $ensure,
    base_path          => "${sensu::etc_dir}/conf.d",
    host               => $sensu::redis_host,
    port               => $sensu::redis_port,
    password           => $sensu::redis_password,
    reconnect_on_error => $sensu::redis_reconnect_on_error,
  }

}
