def nonmaster_agents()
  agents.reject { |agent| agent == master }
end

def apply_simmons_class(agent, studio, classname)
  sitepp = '/etc/puppetlabs/code/environments/production/manifests/site.pp'
  create_remote_file(master, sitepp, <<SITEPP)
class { 'simmons':
  studio    => "#{studio}",
  exercises => [#{classname}],
}
SITEPP
  on(master, "chmod 644 #{sitepp}")
  with_puppet_running_on(master, {"master" => {"autosign" => true}}) do
    on(agent, puppet("agent --test --server #{master}"), :acceptable_exit_codes => [0,2])
  end
end

def rm_vardirs()
  # In order to prevent file caching and ensure agent-master HTTP communication
  # during agent runs we blow away the vardirs, which contains the cached files
  hosts.each do |host|
    vardir = on(host, puppet("config print vardir")).stdout.chomp
    on(host, "rm -rf #{vardir}")
  end
end