#!/usr/bin/env ruby

Facter.add(:roles) do
	setcode do
		primary_role = Facter.value(:role)
		error_msg = '[facter::roles]: "role" value not found'
		raise(error_msg) if primary_role.nil? || primary_role.empty?
		roles = [primary_role]

		roles << :server if ["chunkserver", "primary_server"].include? primary_role

		roles << :base
	end
end
