class idm (
  $base_domain = 'example.org'
) {
  package { ["python-virtualenv"]:
    ensure => installed
  }
  include idm::web

  idm::app {
    core:
      app_package => "idm_core",
      vcs_url => "https://github.com/alexsdutton/idm-core";
    auth:
      app_package => "idm_auth",
      vcs_url => "https://github.com/alexsdutton/idm-auth";
  }
}