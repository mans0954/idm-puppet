class idm::solr {
  $solr_xml = "/etc/solr/solr.xml"
  $core_dir = "/etc/solr/core"

  $required_packages = [
    "solr-tomcat",
  ]

  file {
    $core_dir:
      ensure => directory;
  }

  package { $required_packages:
    ensure => installed;
  }

  concat {
    $solr_xml:
      ensure => present;
  }

  concat::fragment {
    "solr-xml-header":
      target => $solr_xml,
      content => template('idm/solr.xml-header.erb');
    "solr-xml-footer":
      target => $solr_xml,
      content => template('idm/solr.xml-footer.erb');
  }

  define core() {
    $core_dir = "${idm::solr::core_dir}/$name"
    $conf_dir = "$core_dir/conf"


    $conf_files = [
      "admin-extra.html",
      "currency.xml",
      "elevate.xml",
      "lang",
      "mapping-FoldToASCII.txt",
      "mapping-ISOLatin1Accent.txt",
      "protwords.txt",
      "scripts.conf",
      "solrconfig.xml",
      "spellings.txt",
      "stopwords.txt",
      "synonyms.txt",
      "velocity",
      "xslt",
    ]

    $conf_files.each |Integer $index, String $value| {
      file {
        "$conf_dir/$value":
          ensure => symlink,
          target => "/etc/solr/conf/$value";
      }
    }

    file {
      [$core_dir, $conf_dir]:
        ensure => directory;
    }

    concat::fragment {
      "solr-xml-core-$name":
        target => $idm::solr::solr_xml,
        content => template('idm/solr.xml-core.erb')
    }
  }
}