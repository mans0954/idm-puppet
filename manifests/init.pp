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
  $card_server_name = hiera('idm::card::server_name', "card.${base_domain}")
  $integration_server_name = hiera('idm::integration::server_name', "integration.${base_domain}")

  $core_oidc_client_id = hiera('idm::core::oidc::client_id')
  $core_oidc_client_secret = hiera('idm::core::oidc::client_secret')

  $card_oidc_client_id = hiera('idm::card::oidc::client_id')
  $card_oidc_client_secret = hiera('idm::card::oidc::client_secret')

  include postgresql::server

  package { $required_packages:
    ensure => installed
  }
  include idm::broker
  include idm::linotp
  include idm::solr

  class { idm::kerberos:
    realm => $realm,
    domain_realms => hiera('idm::kerberos::domain_realms', [$base_domain])
  }
  class { idm::web:
    alt_names => [
      $core_server_name,
      $auth_server_name,
      $card_server_name,
      $integration_server_name,
    ],
    self_signed_cert => hiera('idm::web::self_signed_cert', true),
  }

  $additional_environment = [
        "IDM_AUTH_URL=https://$auth_server_name/",
        "IDM_AUTH_API_URL=https://$auth_server_name/api/",
        "IDM_CORE_URL=https://$core_server_name/",
        "IDM_CORE_API_URL=https://$core_server_name/api/",
        "IDM_CARD_URL=https://$card_server_name/",
        "IDM_CARD_API_URL=https://$card_server_name/api/",
        "OIDC_ISSUER=https://$auth_server_name/",
        "OIDC_AUTHORIZATION_ENDPOINT=https://$auth_server_name/openid/authorize/",
        "OIDC_TOKEN_ENDPOINT=https://$auth_server_name/openid/token/",
        "OIDC_USERINFO_ENDPOINT=https://$auth_server_name/openid/userinfo/",
        "OIDC_JWKS_URI=https://$auth_server_name/openid/jwks/",
        "OIDC_SIGNING_ALG=RS256",
  ]

  idm::app {
    core:
      app_package => "idm_core",
      vcs_url => "https://github.com/alexsdutton/idm-core",
      server_name => $core_server_name,
      flower_port => 5555,
      solr_core => true,
      additional_environment => $additional_environment + [
        "OIDC_CLIENT_ID=$core_oidc_client_id",
        "OIDC_CLIENT_SECRET=$core_oidc_client_secret",
      ];
    auth:
      app_package => "idm_auth",
      vcs_url => "https://github.com/alexsdutton/idm-auth",
      server_name => $auth_server_name,
      flower_port => 5556,
      additional_environment => $additional_environment;
    card:
      app_package => "idm_card",
      vcs_url => "https://github.com/alexsdutton/idm-card",
      server_name => $card_server_name,
      flower_port => 5557,
      additional_environment => $additional_environment + [
        "OIDC_CLIENT_ID=$card_oidc_client_id",
        "OIDC_CLIENT_SECRET=$card_oidc_client_secret",
      ];
    integration:
      app_package => "idm_integration",
      vcs_url => "https://github.com/alexsdutton/idm-integration",
      server_name => $integration_server_name,
      wsgi_app => false,
      flower_port => 5558,
      additional_environment => $additional_environment;
  }
}
