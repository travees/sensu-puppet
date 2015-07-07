# = Class: sensu::client::service
#
# Manages the Sensu client service
#
# == Parameters
#
# [*hasrestart*]
#   Bolean. Value of hasrestart attribute for this service.
#   Default: true
#
class sensu::client::service (
  $hasrestart = true,
) {

  validate_bool($hasrestart)

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $sensu::manage_services {

    case $sensu::client {
      true: {
        $ensure = 'running'
        $enable = true
      }
      default: {
        $ensure = 'stopped'
        $enable = false
      }
    }

    if $::osfamily == 'windows' {

      file { 'C:/opt/sensu/bin/sensu-client.xml':
        ensure  => present,
        content => template("${module_name}/sensu-client.erb"),
      }

      exec { 'install-sensu-client':
        command => 'sc.exe create sensu-client start= delayed-auto binPath= c:\opt\sensu\bin\sensu-client.exe DisplayName= "Sensu Client"',
        unless  => 'sc.exe query "sensu-client"',
        path    => 'C:\Windows\System32',
        before  => Service['sensu-client'],
        require => File['C:/opt/sensu/bin/sensu-client.xml'],
      }

    }

    service { 'sensu-client':
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => $hasrestart,
      subscribe  => [Class['sensu::package'], Class['sensu::client::config'], Class['sensu::rabbitmq::config'] ],
    }
  }
}
