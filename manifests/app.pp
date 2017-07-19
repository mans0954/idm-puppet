define idm::app (
  $vcs_url,
  $app_package,
  $server_name = undef,
) {
  $home = "/srv/idm-${name}"
  $user = "idm_${name}"
  $repo = "${home}/repo"
  $venv = "${home}/venv"
  $wsgi = "${home}/app.wsgi"
  $celery_vhost = "idm-${name}-celery"

  # Secrets
  $django_secret_key = hiera("idm::${name}::secret_key")
  $amqp_password = hiera("idm::${name}::amqp_password")

  if $server_name == undef {
    $_server_name = "${name}.${idm::base_domain}"
  } else {
    $_server_name = $server_name
  }


  $application_environment = [
    "CELERY_BROKER_URL=amqp://localhost/$celery_vhost",
    "DJANGO_ALLOWED_HOSTS=$_server_name",
    "DJANGO_SETTINGS_MODULE=${app_package}.settings",
    "DJANGO_SECRET_KEY=$django_secret_key",
    "BROKER_SSL=no",
    "BROKER_USERNAME=$user",
    "BROKER_PASSWORD=$amqp_password",
  ]

  user {
    $user:
      ensure => present,
      home => $home,
      managehome => true;
  }

  rabbitmq_user { $user:
    password => $amqp_password,
  }

  rabbitmq_vhost { $celery_vhost:
    ensure => present,
  }

  rabbitmq_user_permissions { "${user}@/":
    configure_permission => "idm\\.${name}\\..*",
    read_permission      => '.*',
    write_permission     => "idm\\.${name}\\..*",
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
      servername => $_server_name,
      port => 80,
      docroot => "$home/docroot",
      redirect_status => 'permanent',
      redirect_dest   => "https://${name}.${idm::base_domain}/";
    "idm-${name}-ssl":
      servername => $_server_name,
      port => 443,
      docroot => "$home/docroot",
      ssl => true,
      wsgi_daemon_process         => "idm-${name}",
      wsgi_daemon_process_options => {
        processes => '2',
        threads => '15',
        display-name => '%{GROUP}',
        python-home => $venv,
        python-path => $repo,
        user => $user,
        group => $user,
      },
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

  postgresql::server::database { $user:
    owner => $user,
  }

  postgresql::server::role { $user:
  }

}