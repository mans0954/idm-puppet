define idm::app (
  $vcs_url,

) {
  $home = "/srv/idm-${name}"
  $user = "idm_${name}"
  $repo = "${home}/repo"
  $venv = "${home}/venv"

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
      ssl => true;
  }

  exec { "idm-${name}-create-virtualenv":
    unless => "[ -d $venv ]",
    command => "/usr/bin/virtualenv3 $venv",
    require => Package["python3-virtualenv"];
  }

}