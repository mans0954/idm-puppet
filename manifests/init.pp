class idm (
  $base_domain = 'example.org'
) {
  include idm::web

  idm::app {
    core:
      vcs_url => "https://github.com/alexsdutton/idm-core";
    auth:
      vcs_url => "https://github.com/alexsdutton/idm-auth";
  }
}