class idm::web (
  $alt_names = [],
){
  $ssl_conf = "/root/cert.conf"
  $ssl_cert = "/etc/ssl/certs/$fqdn.crt"
  $ssl_key = "/etc/ssl/certs/$fqdn.pem"

  file { $ssl_conf:
    content => template('idm/cert.conf.erb');
  }

  exec {
    "create-ssl-cert":
      command => "/usr/bin/openssl req -x509 -config $ssl_conf -newkey rsa:4096 -keyout $ssl_key -out $ssl_cert -days 3650 -nodes",
      creates => $ssl_cert;
    "copy-ssl-cert":
      command => "/bin/cp $ssl_cert /usr/share/ca-certificates/";
    "add-cert-to-ca-certificates":
      command => "/bin/echo '/usr/share/ca-certificates/$fqdn.crt' >> /etc/ca-certificates.conf",
      unless => "/bin/grep $fqdn.crt /etc/ca-certificates.conf",
      provider => "shell";
    "update-ca-certificates":
      command => "/usr/sbin/update-ca-certificates";
  }

  Exec["add-cert-to-ca-certificates"] -> Exec["create-ssl-cert"]
  File[$ssl_conf] ~> Exec["create-ssl-cert"] ~> Exec["copy-ssl-cert"] ~> Exec["update-ca-certificates"]

  class { "apache":
    #default_vhost => false
  }
  class { 'apache::mod::ssl': }
  class { 'apache::mod::wsgi':
    package_name => "libapache2-mod-wsgi-py3",
    mod_path => "mod_wsgi.so"
  }
}