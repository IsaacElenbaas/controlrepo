class profile::primary_server::gonic() {
	# TODO: ensure link home music to herd
	package { "gonic": } -> file_line { "gonic_listen-addr":
		path  => "/var/lib/gonic/config",
		line  => "listen-addr 0.0.0.0:8096",
		match => '^\s*#?\s*listen_addr\s'
	} -> file_line { "gonic_music-path":
		path  => "/var/lib/gonic/config",
		line  => "music-path /media/herd/Music",
		match => '^\s*#?\s*music-path\s'
	} -> file_line { "gonic_podcast-path":
		path  => "/var/lib/gonic/config",
		line  => "podcast-path /var/empty",
		match => '^\s*#?\s*podcast-path\s'
	} -> file_line { "gonic_playlists-path":
		path  => "/var/lib/gonic/config",
		line  => "playlists-path /var/empty",
		match => '^\s*#?\s*playlists-path\s'
	} -> file_line { "gonic_scan-interval":
		path  => "/var/lib/gonic/config",
		line  => "scan-interval 60",
		match => '^\s*#?\s*scan-interval\s'
	} ~> service { "gonic":
		ensure => "running",
		enable => true
	}
}
