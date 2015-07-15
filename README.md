puppet-glusterfs
================

GlusterFS type

This is a beta release. Please review and test carefully before using in production.

Usage
=====
```puppet
node /storage/ {
  class { 'glusterfs': }
  glusterfs_pool { ['192.168.1.100', '192.168.1.101']: } ->
  glusterfs_vol { 'data':
    replica => 2,
    brick   => ['192.168.1.100:/mnt/brick', '192.168.1.101:/mnt/brick'],
  }
}
```

Using hiera:
```yaml
glusterfs::data_dir: '/data/glusterfs'
glusterfs::package::redhat::baseurl: 'https://download.gluster.org/pub/gluster/glusterfs/3.6/3.6.2/EPEL.repo/epel-6/x86_64/'
glusterfs::package::redhat::gpgkey: 'https://download.gluster.org/pub/gluster/glusterfs/3.6/3.6.2/EPEL.repo/pub.key'
glusterfs::package_ensure: '3.6.2-1.el6'
glusterfs::pool:
  GFS01:
    peer: '10.1.1.1'
glusterfs::volumes:
  volume_name:
    force: true
    replica: 2
    brick: ["%{ipaddress}:/data/glusterfs", "10.1.1.1:/data/glusterfs"]
```

Local changes
=============

We experienced a race condition where a server had not completed installation of glusterfs before the volume creation attempt was made.
A simple 10 second sleep was inserted to mitigate. Not so much fixing the issue as putting lipstick on it..

Statsd beaconing was implemented around the glusterfs system calls in line with policy of instrumenting all teh things

```ruby
require 'statsd'

  $statsd = Statsd.new 'localhost', 8125

  def self.instances
    sleep 10
    $statsd.time('deployment.glusterfs.peerstatus') {
      glusterfs('peer','status').split(/\n/).collect do |line|
        if line =~ /Hostname:\s(\S+)$/
          new(:name => $1)
        else
          raise Puppet::Error, "Cannot parse invalid peer line: #{line}"
        end
      end
    }
  end
```
