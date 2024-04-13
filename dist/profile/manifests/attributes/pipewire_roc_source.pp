class profile::attributes::pipewire_roc_source() {
	require Class[::profile::base::pipewire]

	package { "pipewire-roc": } -> file { "/home/isaacelenbaas/.config/pipewire/pipewire.conf.d/roc_source.conf":
		ensure  => "file",
		owner   => "isaacelenbaas",
		group   => "isaacelenbaas",
		content => @(__EOF__),
			context.modules = [
				{
					name = libpipewire-module-roc-source
					args = {
						local.ip = 0.0.0.0
						resampler.profile = medium
						fec.code = rs8m
						sess.latency.msec = 100
						local.source.port = 10001
						local.repair.port = 10002
						source.name = "ROC Source"
						source.props = {
							node.name = "roc-source"
						}
					}
				}
			]
			|__EOF__
	} ~> exec { "if systemctl --user -M isaacelenbaas@ is-active pipewire.service; then systemctl --user -M isaacelenbaas@ restart pipewire.service; else true; fi":
		refreshonly => true,
		provider    => "shell",
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
}
