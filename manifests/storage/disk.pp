# This follow the instructions about creating a disk device
# from http://swift.openstack.org/development_saio.html
#
# It will do two steps to creates a managed disk device:
#   - creates a disk table, each disk table contains one partition (e.g. sdb table contains sdb1)
#   - formats the partition to an xfs device and mounts it as a block device at /srv/node/$name
# ATTENTION: Please don't use your system disk as the param.

define swift::storage::disk(
  $base_dir     = '/dev',
  $mnt_base_dir = '/srv/node',
  $byte_size    = '1024',
) {


  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
    }
  }

  exec { "create_partition_table-${name}":
    command     => "parted -s ${base_dir}/${name} mklabel gpt",
    path        => ['/usr/bin/', '/sbin','/bin'],
    onlyif      => ["test -b ${base_dir}/${name}","parted ${base_dir}/${name} print|tail -1|grep 'Error'"],
  }

  swift::storage::xfs { $name:
    device       => "${base_dir}/${name}",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    loopback     => false,
    subscribe    => Exec["create_partition_table-${name}"],
  }

}
