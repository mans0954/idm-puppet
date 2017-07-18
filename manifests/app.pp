define idm::app (
  $vcs_url,
  $app_package,
) {
  $home = "/srv/idm-${name}"
  $user = "idm_${name}"
  $repo = "${home}/repo"
  $venv = "${home}/venv"
  $wsgi = "${home}/app.wsgi"
  $celery_vhost = "idm-${name}-celery"

  $application_environment = [
    "CELERY_BROKER_URL=amqp://localhost/$celery_vhost",
  ]

  user {
    $user:
      ensure => present,
      home => $home,
      managehome => true;
  }

  rabbitmq_user { $user:
    password => 'bar',
  }

  rabbitmq_vhost { $celery_vhost:
    ensure => present,
  }

  rabbitmq_user_permissions { "${user}@${celery_vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

  vcsrepo { $repo:
    ensure => present,
    provider => git,
    source => $vcs_url,
  }

  apache::vhost {
    "idm-${name}-non-ssl":
      servername => "${name}.${idm::base_domain}",
      port => 80,
      docroot => "$home/docroot",
      redirect_status => 'permanent',
      redirect_dest   => "https://${name}.${idm::base_domain}/";
    "${name}.${idm::base_domain}-ssl":
      servername => "${name}.${idm::base_domain}",
      port => 443,
      docroot => "$home/docroot",
      ssl => true,
      wsgi_daemon_process         => "idm-${name}",
      wsgi_daemon_process_options =>
        { processes => '2', threads => '15', display-name => '%{GROUP}' },
      wsgi_process_group          => "idm-${name}",
      wsgi_script_aliases         => { '/' => $wsgi };
  }

  exec {
    "idm-${name}-create-virtualenv":
      unless => "/usr/bin/test -d $venv",
      command => "/usr/bin/virtualenv $venv --python=/usr/bin/python3",
      require => Package["python-virtualenv"];
    "idm-${name}-install-requirements":
      command => "$venv/bin/pip install -r $repo/requirements.txt",
      require => Exec["idm-${name}-create-virtualenv"];
  }

  file {
    $wsgi:
      content => template('idm/app.wsgi.erb');
  }

}