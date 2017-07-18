define idm::app (
  $vcs_url,

) {
  $home = "/srv/idm-${name}"
  $user = "idm_${name}"
  $repo = "${home}/repo"

  user {
    $user:
      ensure => present,
      home => $home,
      managehome => true;
  }

  vcsrepo { $repo:
    provider => git
  }

  apache::vhost {
    "idm-${name}":
      docroot => "$home/docroot",
      vhost_name => "${name}.${idm::base_domain}";
  }

}