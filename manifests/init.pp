class idm (
  $base_domain = 'example.org',
) {
  $required_packages = [
    "python-virtualenv",
    "gcc",
    "python3-dev",
    "libxslt1-dev",
    "libxml2-dev",
    "libxmlsec1-dev",
    "libkrb5-dev",
    "bison",
  ]

  include postgresql::server

  package { $required_packages:
    ensure => installed
  }
  include idm::broker
  class { idm::kerberos:
    realm => hiera('idm::kerberos::realm', 'EXAMPLE.ORG'),
    domain_realms => hiera('idm::kerberos::domain_realms', ['example.org'])
  }
  include idm::web

  $core_server_name = hiera('idm::core::server_name', "core.${base_domain}")
  $auth_server_name = hiera('idm::auth::server_name', "auth.${base_domain}")

  idm::app {
    core:
      app_package => "idm_core",
      vcs_url => "https://github.com/alexsdutton/idm-core";
    auth:
      app_package => "idm_auth",
      vcs_url => "https://github.com/alexsdutton/idm-auth",
      additional_environment => [
        "IDM_CORE_API_URL=https://$core_server_name/api/",
      ];
  }
}