class profile::primary_server::soulseek() {
	file { "/etc/systemd/system/soulseek-port.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=soulseek port setup
			Wants=network.target
			After=network.target

			[Service]
			Type=oneshot
			RemainAfterExit=true
			ExecStart=bash -c '\
			iptables -A INPUT -p tcp -d localhost --dport ${lookup("soulseek_port")} -j ACCEPT; \
			iptables -A INPUT -p tcp              --dport ${lookup("soulseek_port")} -j DROP  ; \
			:'
			ExecStop=bash -c '\
			iptables -D INPUT -p tcp -d localhost --dport ${lookup("soulseek_port")} -j ACCEPT; \
			iptables -D INPUT -p tcp              --dport ${lookup("soulseek_port")} -j DROP  ; \
			:'

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "soulseek-port.service":
		ensure => "running",
		enable => true
	}
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
			# no ClientAliveInterval support on current seedbox ssh :( use Server
			ExecStart=bash -c '\
			cat /home/isaacelenbaas/.ssh/id_rsa_seedbox     | ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox ${lookup("seedbox_user")}@${lookup("seedbox_address")} "mkdir -p ~/.ssh && cat > ~/.ssh/id_rsa_seedbox && chmod g-r,o-r ~/.ssh/id_rsa_seedbox"; \
			cat /home/isaacelenbaas/.ssh/id_rsa_seedbox.pub | ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox ${lookup("seedbox_user")}@${lookup("seedbox_address")} "mkdir -p ~/.ssh && cat > ~/.ssh/id_rsa_seedbox.pub"; \
			while printf "\\\\n"; do sleep 60; done | ssh -i /home/isaacelenbaas/.ssh/id_rsa_seedbox -o "StrictHostKeyChecking off" -o "ExitOnForwardFailure yes" -tt -R ${lookup("soulseek_port")-1}:localhost:${lookup("soulseek_port")} ${lookup("seedbox_user")}@${lookup("seedbox_address")} "ssh -i ~/.ssh/id_rsa_seedbox -o \\\\"StrictHostKeyChecking off\\\\" -o \\\\"ServerAliveInterval 60\\\\" -o \\\\"ExitOnForwardFailure yes\\\\" -N -T -g -L ${lookup("soulseek_port")}:localhost:${lookup("soulseek_port")-1} localhost & while IFS= read -r -t 65; do :; done; kill \\\\$!"; \
			:'
			Restart=always
			# keep higher than 65s + AliveCountMax (default 3) * AliveInterval to be safe
			# otherwise other side could have not exited while we try to reconnect which breaks
			RestartSec=5m
			|__EOF__
	} -> file { "/etc/systemd/system/soulseek.service":
		ensure  => "file",
		content => @("__EOF__"),
			[Unit]
			Description=soulseek server
			Wants=network.target
			After=network.target
			Requires=soulseek-port-tunnel.service
			After=soulseek-port-tunnel.service

			[Service]
			User=isaacelenbaas
			Group=isaacelenbaas
			Environment="SLSKD_SLSK_USERNAME=${lookup("soulseek_username")}"
			Environment="SLSKD_SLSK_PASSWORD=${lookup("soulseek_password")}"
			ExecStart=slskd \
			--remote-file-management true \
			--shared /media/soulseek \
			--share-cache-retention 1440 \
			--upload-slots 20 \
			--upload-speed-limit 814 \
			--slsk-listen-port ${lookup("soulseek_port")} \
			--slsk-description "" \
			--slsk-proxy true \
			--slsk-proxy-address 127.0.0.1 \
			--slsk-proxy-port 9118 \
			--slsk-proxy-username admin \
			--slsk-proxy-password socks \
			--http-port 8091 \
			--no-https \
			--no-auth \
			--no-disk-logger \
			--no-logo \
			--no-config-watch \
			--no-version-check \
			--case-sensitive-regex
			Restart=always

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	}
	unless find_file("/usr/bin/slskd", "/bin/slskd") {
		warning("Install slskd-bin to have it set up")
	}
	else {
		unless find_file("/media/soulseek") {
			warning("Set up /media/soulseek to have soulseek set up")
		}
		else {
			unless find_file("/home/isaacelenbaas/.ssh/id_rsa_seedbox") {
				warning("Set up id_rsa_seedbox to have soulseek set up")
			}
			else {
				unless "${lookup("seedbox_address")}" != "" and "${lookup("seedbox_user")}" != "" and "${lookup("soulseek_username")}" != "" and "${lookup("soulseek_password")}" != "" {
					warning("Set up seedbox secrets to have soulseek set up")
				}
				else {
					service { "soulseek":
						ensure    => "running",
						enable    => true,
						require   => Service["soulseek-port.service"],
						subscribe => File["/etc/systemd/system/soulseek.service"]
					}
				}
			}
		}
	}
}
