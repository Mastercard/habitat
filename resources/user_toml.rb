# Copyright:: 2017-2018, Chef Software Inc.
# License:: Apache License, Version 2.0
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
# See the License for the specific language governing
resource_name :hab_user_toml
provides :hab_user_toml

property :config, Mash,
         required: true,
         coerce: proc { |m| m.is_a?(Hash) ? Mash.new(m) : m }
property :service_name, String, name_property: true, desired_state: false

action :create do
  directory config_directory do
    mode '0755'
    owner root_owner
    group node['root_group']
    recursive true
  end

  file "#{config_directory}/user.toml" do
    mode '0600'
    owner root_owner
    group node['root_group']
    content toml_dump(new_resource.config)
    sensitive true
  end
end

action :delete do
  file "#{config_directory}/user.toml" do
    sensitive true
    action :delete
  end
end

action_class do
  include Habitat::Toml

  def config_directory
    platform_family?('windows') ? "C:/hab/user/#{new_resource.service_name}/config" : "/hab/user/#{new_resource.service_name}/config"
  end

  def wmi_property_from_query(wmi_property, wmi_query)
    @wmi = ::WIN32OLE.connect('winmgmts://')
    result = @wmi.ExecQuery(wmi_query)
    return nil unless result.each.count > 0
    result.each.next.send(wmi_property)
  end

  def root_owner
    if platform_family?('windows')
      wmi_property_from_query(:name, "select * from Win32_UserAccount where sid like 'S-1-5-21-%-500' and LocalAccount=True")
    else
      'root'
    end
  end
end
