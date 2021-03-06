# For Flannel (overlay network) to work we need to pass bridged IPv4 traffic to iptables’ chains

if node['platform'].eql?('centos')
  # For centos, at least on a VM we need to load some kernel modules
  kernel_module 'bridge' do
    action :install
  end

  kernel_module 'br_netfilter' do
    action :install
  end
end

sysctl_param 'net.bridge.bridge-nf-call-iptables' do
  value 1
end

# Start the docker deamon
service 'docker' do
  action [:enable, :start]
end

# Install g++ to be able to install http-cookie gem
case node['platform']
when 'centos'
  package 'gcc-c++'
when 'ubuntu'
  package 'g++'
end

# Install gem as helper to send Hopsworks requrests to sign certificates
chef_gem 'http-cookie'

hopsworks_ip = private_recipe_ip('hopsworks', 'default')
hopsworks_https_port = 8181
if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('secure_port')
    hopsworks_https_port = node['hopsworks']['secure_port']
  end
end

node.override['kube-hops']['pki']['ca_api'] = "#{hopsworks_ip}:#{hopsworks_https_port}"
