class profile::base::zram() {
	file { "/etc/systemd/system/zram.service":
		ensure  => "file",
		# swappiness is the comparative cost of:
		# 	loading a file from disk that had previously been cached in RAM
		# 	loading that same file from swap
		# and, by default, prioritizes just removing things from cache because the swap is probably on the same disk
		# with swap on zram, it's just. . . more ram. . . so max swappiness
		# so try to cache as much as possible and let the kernel handle swapping less files if it needs to swap actual memory
		content => @("__EOF__"/$),
			[Unit]
			Description=zram configuration

			[Service]
			Type=oneshot
			RemainAfterExit=true
			ExecStart=bash -c 'set -e; \
			modprobe zram; \
			size="${floor($facts["memory"]["system"]["total_bytes"]/1024/1024/1024)}G"; \
			zramctl /dev/zram0 --algorithm zstd --size "\$size"; \
			mkswap -U clear /dev/zram0; \
			swapon --priority 100 -d /dev/zram0; \
			sysctl -w vm.swappiness=200; \
			printf "0" > /sys/module/zswap/parameters/enabled; \
			'

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} ~> service { "zram":
		ensure => "running",
		enable => true
	}
}
