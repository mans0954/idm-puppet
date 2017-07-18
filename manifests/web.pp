class idm::web {
  class { "apache": }

  apache::vhost {
    idm-core:
      vhost_name => "core.${idm::base_domain}";
    idm-auth:
      vhost_name => "auth.${idm::base_domain}";
    idm-card:
      vhost_name => "card.${idm::base_domain}";
  }
}