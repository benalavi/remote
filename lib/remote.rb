require "tempfile"
require "open3"

class Remote
  attr_reader :config, :options
  attr_accessor :env
  
  def initialize(config, options={})
    @config = config
    @options = options
  end
  
  def run(servers, scripts)
    bash = Tempfile.new("remote.sh")
    
    bash.puts %Q{#!/usr/bin/env bash}
    bash.puts %Q{set -e}
    
    (env || {}).each do |k, v|
      bash.puts %Q{export #{k}="#{v}"}
    end
    
    Array(scripts).each do |script|
      raise RuntimeError.new("Could not find recipe #{script}") if !File.exist?(script)
      
      bash.puts %Q{echo "\033[1;33m----- #{script}\033[00m" >&2}
      bash.puts File.read(script)
      bash.puts %Q{echo "\033[01;32mOK\033[00m" >&2}
    end
    
    bash.flush
    
    Array(servers).each do |server|
      Open3.popen3(%Q{bash -c "ssh -T -F #{config} #{server} < #{bash.path}"}) do |stdin, stdout, stderr, wait|
        t_out = buffer(stdout) do |line|
          $stdout.write "#{line}" if options[:verbose]
        end
        
        t_err = buffer(stderr) do |line|
          $stdout.write "\033[01;31m#{line}\033[00m"
        end
        
        t_out.join
        t_err.join
      end
    end
  ensure
    bash.close
    bash.unlink
  end
  
  private
  
  def buffer(stream, &block)
    Thread.new do
      while line = stream.gets
        block.call(line)
      end
    end
  end
end
