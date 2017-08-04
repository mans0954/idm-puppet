class idm::firewall::post {
  firewall {
    "100 allow SSH":
      dport => 22,
      proto => "tcp",
      action => "accept",
      source => hiera("firewall::allow_ssh_from");
    "100 allow HTTP and HTTPS":
      dport => [80, 443],
      proto => "tcp",
      action => "accept",
      source => hiera("firewall::allow_http_from");
  }

  firewall { "999 drop all other requests":
    action => "drop",
  }
}