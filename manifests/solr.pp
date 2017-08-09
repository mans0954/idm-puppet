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
      content => template('idm/solr.xml-header.erb'),
      order => "01";
    "solr-xml-footer":
      target => $solr_xml,
      content => template('idm/solr.xml-footer.erb'),
      order => "99";
  }

  define core(
    $schema_xml,
  ) {
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
      "$conf_dir/schema.xml":
        ensure => file,
        source => $schema_xml;
    }

    concat::fragment {
      "solr-xml-core-$name":
        target => $idm::solr::solr_xml,
        content => template('idm/solr.xml-core.erb'),
        order => "02";
    }
  }
}