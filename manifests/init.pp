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

  $realm = hiera('idm::kerberos::realm', 'EXAMPLE.ORG')
  $core_server_name = hiera('idm::core::server_name', "core.${base_domain}")
  $auth_server_name = hiera('idm::auth::server_name', "auth.${base_domain}")
  $core_oidc_client_id = hiera('idm::core::oidc::client_id')
  $core_oidc_client_secret = hiera('idm::core::oidc::client_secret')

  include postgresql::server

  package { $required_packages:
    ensure => installed
  }
  include idm::broker
  include idm::linotp
  class { idm::kerberos:
    realm => $realm,
    domain_realms => hiera('idm::kerberos::domain_realms', [$base_domain])
  }
  class { idm::web:
    alt_names => [
      $core_server_name,
      $auth_server_name,
    ]
  }

  idm::app {
    core:
      app_package => "idm_core",
      vcs_url => "https://github.com/alexsdutton/idm-core",
      server_name => $core_server_name,
      flower_port => 5555,
      additional_environment => [
        "IDM_AUTH_URL=https://$auth_server_name/",
        "IDM_AUTH_API_URL=https://$auth_server_name/api/",
        "OIDC_ISSUER=https://$auth_server_name/",
        "OIDC_AUTHORIZATION_ENDPOINT=https://$auth_server_name/openid/authorize/",
        "OIDC_TOKEN_ENDPOINT=https://$auth_server_name/openid/token/",
        "OIDC_USERINFO_ENDPOINT=https://$auth_server_name/openid/userinfo/",
        "OIDC_JWKS_URI=https://$auth_server_name/openid/jwks/",
        "OIDC_CLIENT_ID=$core_oidc_client_id",
        "OIDC_CLIENT_SECRET=$core_oidc_client_secret",
        "OIDC_SIGNING_ALG=RS256",
      ];
    auth:
      app_package => "idm_auth",
      vcs_url => "https://github.com/alexsdutton/idm-auth",
      server_name => $auth_server_name,
      flower_port => 5556,
      additional_environment => [
        "IDM_CORE_URL=https://$core_server_name/",
        "IDM_CORE_API_URL=https://$core_server_name/api/",
      ];
  }
}