class idm::kerberos (
  $realm,
  $domain_realms,
) {
  $krb5_conf = "/etc/krb5.conf"
  $kdc_conf = "/etc/krb5kdc/kdc.conf"
  $master_password = hiera('idm::kerberos::master_password')

  $required_packages = [
    "krb5-admin-server",
    "krb5-kdc",
  ]

  package {
    $required_packages:
      ensure => installed;
  }

  file {
    $krb5_conf:
      content => template('idm/krb5.conf.erb');
    "/etc/krb5kdc/":
      ensure => directory;
    $kdc_conf:
      content => template('idm/kdc.conf.erb');
  }

  exec { "create-kerberos-realm":
    command => "/usr/sbin/kdb5_util create -r $realm -s <<< '$master_password\n$master_password'",
    unless => "/usr/bin/test -e /etc/krb5kdc/principal",
  }

  service {
    "krb5-kdc":
      ensure => running;
    "krb5-admin-server":
      ensure => running;
  }

  Package["krb5-kdc"] -> File[$krb5_conf] -> Service["krb5-kdc"]
  Package["krb5-admin-server"] -> File[$kdc_conf] -> Exec["create-kerberos-realm"] -> Service["krb5-admin-server"]
}
