class profile::primary_server::gonic() {
	unless find_file("/usr/bin/gonic", "/bin/gonic") {
		warning("Install gonic to have it set up")
	}
	else {
		file_line { "gonic_listen-addr":
			path  => "/var/lib/gonic/config",
			line  => "listen-addr 0.0.0.0:8097",
			match => '^\s*#?\s*listen-addr\s'
		} -> file_line { "gonic_music-path":
			path  => "/var/lib/gonic/config",
			line  => "music-path /media/herd/Music",
			match => '^music-path\s'
		} -> file_line { "gonic_podcast-path":
			path  => "/var/lib/gonic/config",
			line  => "podcast-path /var/empty",
			match => '^podcast-path\s'
		} -> file_line { "gonic_playlists-path":
			path  => "/var/lib/gonic/config",
			line  => "playlists-path /var/empty",
			match => '^playlists-path\s'
		} -> file_line { "gonic_scan-interval":
			path  => "/var/lib/gonic/config",
			line  => "scan-interval 60",
			match => '^\s*#?\s*scan-interval\s'
		} ~> service { "gonic":
			enable => true
		}
	}
}
