require "remote"

class Remote
  class Task
    class Error;end;
  
    Root = File.join(Dir.pwd, "deploy")
    Layout = File.join(Root, "layout.json")
    SSH = File.join(Root, "ssh_config")
  
    def initialize(&block)
      remote = Remote.new SSH, verbose: (ENV["VERBOSE"] =~ /^t/)
    
      environment = ENV["ENV"]
      raise Error.new("No environment specified. Please provide an environment to run in -- i.e. rake deploy ENV=production") if !environment
    
      layout = JSON.parse File.read(Layout)
      raise Error.new("No environment defined for '#{environment}' in #{Layout}") if !layout["environments"].has_key?(environment)
    
      layout["environments"][environment].each do |role, servers|
        block.call remote, role, servers, layout, environment
      end
    rescue Remote::Task::Error => e
      puts e
      exit 255
    end
  end
end
