# = Class: sensu::package
#
# Installs the Sensu packages
#
class sensu::package {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case $::osfamily {

    'Debian': {
      $package_name = 'sensu'
      $package_source = undef
      $package_require = undef
      
      class { 'sensu::repo::apt': }
      if $sensu::install_repo {
        include apt
        $repo_require = Apt::Source['sensu']
      } else {
        $repo_require = undef
      }
    }

    'RedHat': {
      $package_name = 'sensu'
      $package_source = undef
      $package_require = undef
 
      class { 'sensu::repo::yum': }
      if $sensu::install_repo {
        $repo_require = Yumrepo['sensu']
      } else {
        $repo_require = undef
      }
    }

    'windows': {
      $repo_require = undef

      $package_version = inline_template("<%= scope.lookupvar('sensu::version').sub(/(.*)\./, '\1-') %>")
      $package_name = 'Sensu'
      $package_source = "C:\\Windows\\Temp\\sensu-${package_version}.msi"
      $package_require = "Archive[${package_source}]"

      archive { $package_source:
        ensure   => present,
        provider => faraday,
        source   => "http://repos.sensuapp.org/msi/sensu-${package_version}.msi",
        creates  => $package_source,
        cleanup  => false,
      }
    }

    default: { fail("${::osfamily} not supported yet") }

  }

  $conf_dir = "${sensu::etc_dir}/conf.d"
  
  package { $package_name:
    ensure   => $sensu::version,
    source   => $package_source,
    require  => $package_require,
  }

  if $::sensu::sensu_plugin_provider {
    $plugin_provider = $::sensu::sensu_plugin_provider
  } else {
    $plugin_provider = $sensu::use_embedded_ruby ? {
      true    => 'sensu_gem',
      default => 'gem',
    }
  }

  if $plugin_provider =~ /gem/ and $::sensu::gem_install_options {
    package { $::sensu::sensu_plugin_name :
      ensure          => $sensu::sensu_plugin_version,
      provider        => $plugin_provider,
      install_options => $::sensu::gem_install_options,
    }
  } else {
    package { $::sensu::sensu_plugin_name :
      ensure   => $sensu::sensu_plugin_version,
      provider => $plugin_provider,
    }
  }

  if $::osfamily != 'windows' {
    file { '/etc/default/sensu':
      ensure  => file,
      content => template("${module_name}/sensu.erb"),
      owner   => '0',
      group   => '0',
      mode    => '0444',
      require => Package['sensu'],
    }
  }

  file { [ $conf_dir, "${conf_dir}/handlers", "${conf_dir}/checks", "${conf_dir}/filters", "${conf_dir}/extensions" ]:
    ensure  => directory,
    owner   => $sensu::user,
    group   => $sensu::group,
    mode    => $sensu::dir_mode,
    purge   => $sensu::purge_config,
    recurse => true,
    force   => true,
    require => Package[$package_name],
  }

  file { ["${sensu::etc_dir}/handlers", "${sensu::etc_dir}/extensions", "${sensu::etc_dir}/mutators", "${sensu::etc_dir}/extensions/handlers"]:
    ensure  => directory,
    owner   => $sensu::user,
    group   => $sensu::group,
    mode    => $sensu::dir_mode,
    require => Package[$package_name],
  }

  if $sensu::_manage_plugins_dir {
    file { "${sensu::etc_dir}/plugins":
      ensure  => directory,
      owner   => $sensu::user,
      group   => $sensu::group,
      mode    => $sensu::dir_mode,
      purge   => $sensu::purge_plugins_dir,
      recurse => true,
      force   => true,
      require => Package[$package_name],
    }
  }

  if $sensu::manage_user {
    user { 'sensu':
      ensure  => 'present',
      system  => true,
      home    => '/opt/sensu',
      shell   => '/bin/false',
      comment => 'Sensu Monitoring Framework',
    }

    group { 'sensu':
      ensure => 'present',
      system => true,
    }
  }

  file { "${sensu::etc_dir}/config.json": ensure => absent }
}
