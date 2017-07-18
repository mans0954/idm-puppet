class idm::web {
  class { "apache":
    #default_vhost => false
  }
  class { 'apache::mod::ssl': }
  class { 'apache::mod::wsgi': }
}