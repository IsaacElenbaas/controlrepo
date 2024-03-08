class profile::server() {
	class { "::profile::server::moosefs":
		require => Package["moosefs"]
	}
}
