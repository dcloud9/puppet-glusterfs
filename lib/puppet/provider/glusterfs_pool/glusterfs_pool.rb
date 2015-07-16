require 'puppet'
require 'pp'
require 'statsd'
Puppet::Type.type(:glusterfs_pool).provide(:glusterfs) do

  $statsd = Statsd.new 'localhost', 8125

  commands :glusterfs => 'gluster'
  defaultfor :feature => :posix

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

  def create
    sleep 10
    $statsd.time('deployment.glusterfs.peerprobe') {
      glusterfs('peer','probe', resource[:name])
    }
  end

  def destroy
    $statsd.time('undeployment.glusterfs.detach') {
      glusterfs('peer','detach', resource[:name])
    }
  end

  def exists?
    @interfaces = Facter.value(:interfaces).split(',')
    @addresses = @interfaces.map! { |address| Facter.value("ipaddress_#{address}") } |
      ['fqdn', 'hostname'].map! { |hosts| Facter.value("#{hosts}") }
    glusterfs('peer', 'status').split(/\n/).detect do |line|
      if @addresses.include?(resource[:name])
        return 1
      else
        line.match(/^Hostname:\s#{Regexp.escape(resource[:name])}$/)
      end
    end
  end
end
