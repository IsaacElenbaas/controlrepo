class profile::base::pipewire() {
	package { ["pipewire", "pipewire-alsa", "pipewire-jack", "pipewire-pulse"]: } -> file { "/home/isaacelenbaas/.config/pipewire":
		ensure  => "directory",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas"
	} -> file { "/home/isaacelenbaas/.config/pipewire/pipewire.conf.d":
		ensure  => "directory",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas"
	}
}
