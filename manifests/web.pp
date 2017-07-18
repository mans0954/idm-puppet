class idm::web {
  class { "apache":
    #default_vhost => false
  }
  class { 'apache::mod::ssl': }
  class { 'apache::mod::wsgi':
    package_name => "libapache2-mod-wsgi-py3",
    mod_path => "wsgi.conf"
  }
}