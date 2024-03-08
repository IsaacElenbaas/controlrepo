class profile::base::tailscale() {
	package { "tailscale": } ~> service { "tailscaled":
		ensure => "running",
		enable => true
	} -> exec { "tailscale status":
		path => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
	# tailscale up --authkey KEY
	# or just tailscale up, will give URL which can open on something else
}
