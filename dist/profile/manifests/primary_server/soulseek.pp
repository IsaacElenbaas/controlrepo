class profile::primary_server::soulseek() {
	file { "/etc/systemd/system/soulseek-port-tunnel.service":
		ensure  => "file",
		content => @("__EOF__"/$),
			[Unit]
			Description=soulseek port tunnel
			Wants=network.target
			After=network.target
			Requires=soulseek-port.service
			After=soulseek-port.service

			[Service]
			# no ClientAliveInterval support on current seedbox ssh :(
			ExecStart=bash -c '\
			cat /home/isaacelenbaas/.ssh/id_rsa_seedbox     | ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox ${lookup("seedbox_user")}@${lookup("seedbox_address")} "mkdir -p ~/.ssh && cat > ~/.ssh/id_rsa_seedbox && chmod g-r,o-r ~/.ssh/id_rsa_seedbox"; \
			cat /home/isaacelenbaas/.ssh/id_rsa_seedbox.pub | ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox ${lookup("seedbox_user")}@${lookup("seedbox_address")} "mkdir -p ~/.ssh && cat > ~/.ssh/id_rsa_seedbox.pub"; \
			ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox -o "StrictHostKeyChecking off" -o "ServerAliveInterval 60" -T -o "ExitOnForwardFailure yes" -R 46098:localhost:46099 ${lookup("seedbox_user")}@${lookup("seedbox_address")} \
			"ssh -i ~/.ssh/id_rsa_seedbox -g -o \\\\"StrictHostKeyChecking off\\\\" -o \\\\"ServerAliveInterval 60\\\\" -N -T -o \\\\"ExitOnForwardFailure yes\\\\" -L 46099:localhost:46098 localhost"; \
			:'
			Restart=always
			# keep higher than AliveCountMax (default 3) * AliveInterval
			# otherwise other side could not exit and try to reconnect which breaks
			RestartSec=5m
			|__EOF__
	} -> file { "/etc/systemd/system/soulseek.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=soulseek server
			Wants=network.target
			After=network.target
			Requires=soulseek-port-tunnel.service
			After=soulseek-port-tunnel.service

			[Service]
			User=isaacelenbaas
			Group=isaacelenbaas
			ExecStart=bash -c '\
			proxychains nicotine --headless & \
			soulseek="\$\$!"; \
			sleep 5m; \
			while true; do \
			sleep 2h; \
			kill -0 \$\$soulseek || exit 1; \
			proxychains nicotine --rescan; \
			done; \
			:'
			Restart=always

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	}
	unless find_file("/media/soulseek") {
		warning("Set up /media/soulseek to have soulseek set up")
	}
	else {
		unless find_file("/home/isaacelenbaas/.ssh/id_rsa_seedbox") {
			warning("Set up id_rsa_seedbox to have soulseek set up")
		}
		else {
			unless "${lookup("seedbox_address")}" != "" and "${lookup("seedbox_user")}" != "" {
				warning("Set up seedbox secrets to have soulseek set up")
			}
			else {
				service { "soulseek":
					ensure    => "running",
					enable    => true,
					subscribe => [File["/etc/systemd/system/soulseek.service"], Class["profile::base::proxychains"]]
				}
			}
		}
	}
}
