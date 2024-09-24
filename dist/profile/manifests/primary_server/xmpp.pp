class profile::primary_server::xmpp() {
	package { ["prosody", "lua52-sec", "lua52-zlib"]: } -> file { "/etc/prosody/prosody.cfg.lua":
		ensure  => "file",
		source  => "puppet:///modules/${module_name}/primary_server/prosody.cfg.lua"
	} ~> service { "prosody":
		ensure => "running",
		enable => true
	}
}

