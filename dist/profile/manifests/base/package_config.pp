class profile::base::package_config() {
	file_line { "pacman_parallel":
		path  => "/etc/pacman.conf",
		line  => "ParallelDownloads = 5",
		match => '^#?ParallelDownloads'
	}
	exec { "pacman --noconfirm -Syu":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}
	file_line { "pacman_multilib_1":
		path  => "/etc/pacman.conf",
		line  => "[multilib]",
		# no hashtag here is intentional
		match => '^\s*\s*\[multilib\]$'
	} ~> exec { 'printf "Include = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf':
		refreshonly => true,
		provider    => "shell",
		notify      => Exec["pacman --noconfirm -Syu"],
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	#~> file_line { "pacman_multilib_2":
	#	path    => "/etc/pacman.conf",
	#	line    => "Include = /etc/pacman.d/mirrorlist",
	#	# can't match because it will match earlier ones
	#	# after doesn't apply to match, just where to add it
	#	#match   => '^\s*#?\s*Include\s*=\s*/etc/pacman.d/mirrorlist$',
	#	after   => '^\[multilib\]$',
	#	replace => false
	} -> file_line { "pacman_archzfs":
		path  => "/etc/pacman.conf",
		line  => "[archzfs]",
		# no hashtag here is intentional
		match => '^\s*\s*\[multilib\]$'
	} ~> exec { 'printf "Server = http://archzfs.com/\\$repo/\\$arch\n" >> /etc/pacman.conf':
		refreshonly => true,
		provider    => "shell",
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} ~> exec { "pacman-key --recv-keys DDF7DB817396A49B2A2723F7403BD972F75D9D76":
		refreshonly => true,
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} ~> exec { "pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76":
		refreshonly => true,
		notify      => Exec["pacman --noconfirm -Syu"],
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	}

	package { "reflector": }
	~> exec { "reflector -c \"United States\" -f 10 --save /etc/pacman.d/mirrorlist":
		refreshonly => true,
		subscribe   => File["/etc/localtime"],
		path        => "/usr/local/sbin:/usr/sbin:/usr/local/bin:/usr/bin"
	} -> file { "/sbin/update":
		ensure => "file",
		source => "puppet:///modules/${module_name}/base/update",
		mode   => "0755"
	}

	exec {
		@("__EOF__"/n):
		set -e; \
		command -v yay &>/dev/null || { \
			pacman --noconfirm -S --needed git base-devel; \
			git clone "https://aur.archlinux.org/yay-bin.git"; \
			chown -R nobody:nobody yay-bin; cd yay-bin; \
			runuser -unobody -- makepkg -s || { cd ..; rm -rf yay-bin; false; }; \
			pacman --noconfirm -U yay-bin-*.pkg.tar.zst || true; \
		}; \
		cd ..; rm -rf yay-bin; \
		command -v yay &>/dev/null
		|__EOF__
		provider => "shell"
	}
}
