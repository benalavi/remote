require "remote/task"
require "json"

namespace :remote do
  desc "Deploy application"
  task :deploy do
    Remote::Task.new do |remote, role, servers, layout, environment|
      recipes = layout["roles"][role]
      raise Remote::Task::Error.new("Undefined role #{role}") if !layout["roles"].has_key?(role)
      
      remote.env = { "DEPLOY_ENV" => environment }
      remote.run servers, recipes.collect{ |script| File.join(Remote::Task::Root, "recipes", "#{script}.sh") }
    end
  end
  
  desc "Authorize a key for all servers in the given environment"
  task :auth do
    ssh_key = ENV["SSH_KEY"]
    
    if !ssh_key || ssh_key.empty?
      puts "No SSH_KEY specified. Please provide a SSH_KEY to authorize -- i.e. rake remote:auth ENV=production SSH_KEY=\"ssh-rsa AAQx...JHlz==\""
      exit 255
    end
    
    Remote::Task.new do |remote, role, servers, layout, environment|
      remote.env = { "SSH_KEY" => ssh_key }
      remote.run servers, File.join(File.dirname(__FILE__), "..", "..", "recipes", "keyauth.sh")
    end
  end
end
