
class scaleio::firewall::post { 
	firewall { '999 drop all': 
		proto => 'all', 
		action => 'drop', 
		before => undef, 
	} 
}