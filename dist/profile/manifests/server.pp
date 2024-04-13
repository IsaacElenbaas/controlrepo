class profile::server() {
	class { "::profile::server::moosefs":
		require => Package["moosefs"]
	}

	include ::profile::server::tty1
}
