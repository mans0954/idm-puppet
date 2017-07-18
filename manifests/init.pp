class idm (
  $base_domain = 'example.org'
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

  package { $required_packages:
    ensure => installed
  }
  include idm::broker
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