class profile::base::soulseek() {
	package { "nicotine+": }
	file { "/etc/systemd/system/soulseek-port.service":
		ensure  => "file",
		content => @(__EOF__),
			[Unit]
			Description=soulseek port setup
			Wants=network.target
			After=network.target

			[Service]
			Type=oneshot
			RemainAfterExit=true
			ExecStart=bash -c '\
			iptables -A INPUT -p tcp -d localhost --dport 46099 -j ACCEPT; \
			iptables -A INPUT -p tcp              --dport 46099 -j DROP; \
			iptables -A INPUT -p tcp              --dport  2234 -j DROP; \
			:'
			ExecStop=bash -c '\
			iptables -D INPUT -p tcp -d localhost --dport 46099 -j ACCEPT; \
			iptables -D INPUT -p tcp              --dport 46099 -j DROP  ; \
			iptables -D INPUT -p tcp              --dport  2234 -j DROP; \
			:'

			[Install]
			WantedBy=multi-user.target
			|__EOF__
	} -> service { "soulseek-port.service":
		ensure => "running",
		enable => true
	}
	file_line { "sudo_soulseek_stop":
		path  => "/etc/sudoers",
		line  => "isaacelenbaas ALL= NOPASSWD: /bin/systemctl stop soulseek.service"
	} -> file_line { "sudo_soulseek_start":
		path  => "/etc/sudoers",
		line  => "isaacelenbaas ALL= NOPASSWD: /bin/systemctl start soulseek.service"
	} -> file_line { "sudo_soulseek_restart":
		path  => "/etc/sudoers",
		line  => "isaacelenbaas ALL= NOPASSWD: /bin/systemctl restart soulseek.service"
	}
	file { "/usr/share/applications/org.nicotine_plus.Nicotine.desktop":
		ensure  => "file",
		content => @(__EOF__),
			[Desktop Entry]
			Type=Application
			Version=1.1
			Name=Nicotine+
			GenericName=Soulseek Client
			Comment=Graphical client for the Soulseek peer-to-peer network
			Icon=org.nicotine_plus.Nicotine
			Exec=bash -c "sudo /bin/systemctl stop soulseek.service; proxychains nicotine; sudo /bin/systemctl start soulseek.service"
			Terminal=false
			Categories=Network;FileTransfer;InstantMessaging;Chat;P2P;GTK;
			Keywords=Soulseek;Nicotine;sharing;chat;messaging;P2P;peer-to-peer;GTK;
			StartupNotify=true
			X-GNOME-SingleWindow=true
			X-GNOME-UsesNotifications=true
			|__EOF__
	}
}
