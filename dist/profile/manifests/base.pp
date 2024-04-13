class profile::base() {
	stage { "core": before => Stage["main"] }
	class { "::profile::base::core": stage => "core" }
	class { "::profile::base::internet": stage => "core" }
	class { "::profile::base::package_config": stage => "core" }
	class { "::profile::base::tailscale": stage => "core" }

	# TODO: default first_boot fact to true
	# only set first boot to true and reboot once everything has succeeded
	stage { "first_boot": require => Stage["main"] }
	class first_boot {
		# TODO: schedule reboot after this if first boot false
		file { "/etc/facter/facts.d/first_boot.txt":
			ensure => "file",
			content => "first_boot=false\n"
		}
	}

	# TODO: basic dotfiles setup, things that can't fail - e.g. ssh config
	include ::profile::base::misc_startup
	include ::profile::base::moosefs
	include ::profile::base::packages
	include ::profile::base::puppet
	include ::profile::base::zram
}
