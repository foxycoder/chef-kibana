#
# Cookbook Name:: kibana
# Recipe:: nginx
#
# Copyright 2013, John E. Vincent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'base64'

node.set['nginx']['default_site_enabled'] = node['kibana']['nginx']['enable_default_site']

# Create a directory for the healtcheck static HTML file
directory node[:kibana][:nginx][:healthcheck_dir] do
  action :create
  recursive true
end

# Create the healthcheck static HTML file to satisfy ELB (workaround for htpasswd protection)
cookbook_file "#{node[:kibana][:nginx][:healthcheck_dir]}/check.html" do
  source "check.html"
end


include_recipe "nginx"

es_instances = node[:opsworks][:layers][:elasticsearch][:instances]
es_hosts = es_instances.map{ |name, attrs| attrs['private_ip'] }

unless es_hosts.empty?
  node.set['kibana']['es_server'] = es_hosts.first
end

template "/etc/nginx/sites-available/kibana" do
  source node['kibana']['nginx']['template']
  cookbook node['kibana']['nginx']['template_cookbook']
  notifies :reload, "service[nginx]"
  variables(
    :es_server => node['kibana']['es_server'],
    :es_port   => node['kibana']['es_port'],
    :server_name => node['kibana']['webserver_hostname'],
    :server_aliases => node['kibana']['webserver_aliases'],
    :kibana_dir => node['kibana']['installdir'],
    :listen_address => node['kibana']['webserver_listen'],
    :listen_port => node['kibana']['webserver_port']
  )
end

nginx_site "kibana"
