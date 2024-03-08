class profile::primary_server() {
	class { "::profile::primary_server::internet":
		stage  => "core",
		before => Class["profile::base::internet"]
	}

	class { "::profile::primary_server::moosefs":
		require => Package["moosefs"],
		before  => Class["profile::server::moosefs"]
	}

	# TODO: is in AUR, figure out how to do that and make it depend on yay
	#include ::profile::primary_server::gonic
	include ::profile::primary_server::node
}
