
class scaleio::shm inherits scaleio {
	$shm_size              = $scaleio::shm_size

	exec { 'shm':
	  command => "mount -o remount -o size=${shm_size} /dev/shm",
	  path => ["/bin","/usr/bin"],
	  onlyif => [ "test `df -B1 /dev/shm | awk '/\/dev\/shm/ { print \$4; }'` -lt ${shm_size}" ],
	} ->

#	`cat /etc/fstab | grep "/dev/shm" | awk '{ print $4;}' | awk -F, '{ print $2}' | grep size | awk -F= '{ print $2}'`
	file_line { 'Replace a line in fstab':
	    path => '/etc/fstab',
	    match => "^tmpfs",
	    line => "tmpfs  /dev/shm  tmpfs defaults,size=${shm_size}  0 0",
	} ->

		if ($::kernelshmmax.scanf("%i")[0] < 209715200) {
	    exec {'set kernel shmmax' :
	      command   => 'sysctl -p 209715200',
	      logoutput => true,
	      path      => '/sbin',
	    }
    } else { notify {'kernelshmmax set correctly':} }
}
