define idm::app (
  $vcs_url,
  $app_package,
) {
  $home = "/srv/idm-${name}"
  $user = "idm_${name}"
  $repo = "${home}/repo"
  $venv = "${home}/venv"
  $wsgi = "${home}/app.wsgi"

  user {
    $user:
      ensure => present,
      home => $home,
      managehome => true;
  }

  vcsrepo { $repo:
    ensure => present,
    provider => git,
    source => $vcs_url,
  }

  apache::vhost {
    "${name}.${idm::base_domain}":
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