class idm::kerberos (
  $realm,
  $domain_realms,
) {
  $krb5_conf = "/etc/krb5.conf"
  $kdc_conf = "/etc/krb5kdc/kdc.conf"
  $kadm5_acl = "/etc/krb5kdc/kadm5.acl"
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
    $kadm5_acl:
      content => template('idm/kadm5.acl.erb');
  }

  exec { "create-kerberos-realm":
    command => "/bin/bash -c \"/usr/sbin/kdb5_util create -r $realm -s <<< '$master_password\n$master_password'\"",
    unless => "/usr/bin/test -e /etc/krb5kdc/principal",
  }

  service {
    "krb5-kdc":
      ensure => running;
    "krb5-admin-server":
      ensure => running;
  }

  Package["krb5-kdc"] -> File[$krb5_conf] -> Exec["create-kerberos-realm"] -> Service["krb5-kdc"]
  Package["krb5-admin-server"] -> File[$kdc_conf] -> File[$kadm5_acl] -> Service["krb5-admin-server"]

  define keytab_entry($filename) {
    exec {
      "create-principal-$name":
        command => "/usr/sbin/kadmin.local ank -randkey $name",
        unless => "/bin/test \"$(/usr/sbin/kadmin.local listprincs $name)\"",
        provider => shell;
      "extract-keytab-$name":
        command => "/usr/sbin/kadmin.local ktadd -k $filename $name",
        unless => "/usr/bin/klist -k $filename | grep $name",
        provider => shell;
    }

  }

  define keytab ($owner, $group, $principals) {
    idm::kerberos::keytab_entry { $principals:
      filename => $name,
      before => File[$name]
    }

    file {
      $name:
        ensure => present,
        owner => $owner,
        group => $group,
        mode => 600;
    }
  }

}
