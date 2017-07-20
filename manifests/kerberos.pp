class idm::kerberos (
  $realm,
  $domain_realms,
) {
  $krb5_conf = "/etc/krb5.conf"
  $kdc_conf = "/etc/krb5kdc/kdc.conf"

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
    $kdc_conf:
      content => template('idm/kdc.conf.erb');
  }

  service {
    "krb5-kdc":
      ensure => running;
    "krb5-admin-server":
      ensure => running;
  }

  Package["krb5-kdc"] -> File[$krb5_conf] -> Service["krb5-kdc"]
  Package["krb5-admin-server"] -> File[$kdc_conf] -> Service["krb5-admin-server"]
}
