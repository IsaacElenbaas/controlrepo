class profile::primary_server() {
	# TODO: stop things like gonic and soulseek if not primary server anymore
	# TODO: don't need to remove everything, but stop services
	# TODO: can also stop pihole and arch-delugevpn

	class { "::profile::primary_server::internet":
		stage  => "core",
		before => Class["profile::base::internet"]
	}

	class { "::profile::primary_server::moosefs":
		require => Package["moosefs"],
		before  => Class["profile::server::moosefs"]
	}

	include ::profile::primary_server::ddnet
	include ::profile::primary_server::gonic
	include ::profile::primary_server::letsencrypt
	include ::profile::primary_server::node
	include ::profile::primary_server::proxy
	include ::profile::primary_server::soulseek
	include ::profile::primary_server::xmpp

	unless find_file("/media/arch-privoxyvpn") {
		warning("Set up /media/arch-privoxyvpn for slskd")
	}
	unless find_file("/media/docker-pi-hole") {
		warning("Set up /media/docker-pi-hole to have bind set up")
	}
}
