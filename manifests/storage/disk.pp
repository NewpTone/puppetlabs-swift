# follow the instructions for creating a disk device
# for storage from: http://swift.openstack.org/development_saio.html
#
#
# creates a managed partition for useage
#   - creates a disk table, each disk table contains one partition (e.g. sdb table contains sdb1)
#   - formats the partirion to be an xfs device and mounts it as a block device at /srv/node/$name
#   - sets up each mount point as a swift endpoint
# ATTENTION:please don't use your system disk as params.(I just set sda as default)

define swift::storage::disk(
  $base_dir     = '/dev',
  $mnt_base_dir = '/srv/node',
) {

  if(!defined(File[$base_dir])) {
    file { $base_dir:
      ensure => directory,
    }
  }

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
    }
  }
  
  exec { "create_partition_table-${name}":
    command     => "parted -s ${base_dir}/${name} mklabel msdos",
    path        => ['/usr/bin/', '/sbin','/bin'],
    onlyif      => ["test -b ${base_dir}/${name}","parted ${base_dir}/${name} print|tail -1|grep 'Error'"],
  }

  exec {"create_partition-${name}":
	command	   => "parted -s ${base_dir}/${name} mkpart primary 0% 100%", 
	path	   => ['/usr/bin','/sbin','/bin'],
	onlyif	   => ["parted ${base_dir}/${name} print|tail -2|grep 'Number'",
			"test ${name} != 'sda'"],
	subscribe  => Exec["create_partition_table-${name}"],
  }


  swift::storage::xfs { $name:
    device       => "${base_dir}/${name}1",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    subscribe    => Exec["create_partition-${name}"],
    loopback     => false,
    force	 => '',
  }

}
