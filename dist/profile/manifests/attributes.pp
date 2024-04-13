class profile::attributes() {
	parsejson($facts["attributes"]).each |$attribute| {
		class { "::profile::attributes::$attribute": }
	}
}
