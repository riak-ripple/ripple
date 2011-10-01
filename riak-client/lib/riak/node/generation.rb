require 'yaml'

module Riak
  class Node
    # Does the node exist on disk?    
    def exist?
      manifest.exist?
    end
    
    # Deletes the node and regenerates it.
    def recreate
      delete
      create
    end

    # Generates the node.
    def create
      unless exist?
        create_directories
        write_scripts
        write_vm_args
        write_app_config
        write_manifest
      end
    end

    # Clears data from known data directories. Stops the node if it is
    # running.
    def drop
      was_started = started?
      stop if was_started
      data.children.each {|dir| dir.children.each {|c| c.rmtree } }
      start if was_started
    end

    # Removes the node from disk and freezes the object.
    def destroy
      delete
      freeze
    end

    protected
    def delete
      stop unless stopped?
      root.rmtree if root.exist?
    end

    def create_directories
      root.mkpath
      NODE_DIRECTORIES.each {|d| send(d).mkpath }
    end

    def write_vm_args
      (etc + 'vm.args').open('w') do |f|
        vm.each do |k,v|
          f.puts "#{k} #{v}"
        end
      end
    end

    def write_app_config
      (etc + 'app.config').open('w') do |f|
        f.write to_erlang_config(env) + '.'
      end
    end

    def write_scripts
      [control_script, admin_script].each {|s| write_script(s.basename, s) }
    end

    def write_script(name, target)
      source_script = source + name
      target.open('wb') do |f|
        source_script.readlines.each do |line|
          line.sub!(/(RUNNER_SCRIPT_DIR=)(.*)/, '\1' + bin.to_s)
          line.sub!(/(RUNNER_ETC_DIR=)(.*)/, '\1' + etc.to_s)
          line.sub!(/(RUNNER_USER=)(.*)/, '\1')
          line.sub!(/(RUNNER_LOG_DIR=)(.*)/, '\1' + log.to_s)
          line.sub!(/(PIPE_DIR=)(.*)/, '\1' + pipe.to_s)
          if line.strip == "RUNNER_BASE_DIR=${RUNNER_SCRIPT_DIR%/*}"
            line = "RUNNER_BASE_DIR=#{source.parent.to_s}\n"
          end
          f.write line
        end
      end
      target.chmod 0755
    end

    def write_manifest
      # TODO: For now this only saves the information that was used when
      # configuring the node. Later we'll verify/warn if the settings
      # used differ on subsequent generations.
      @configuration[:env] = @env
      @configuration[:vm] = @vm
      manifest.open('w') {|f| YAML.dump(@configuration, f) }
    end
  end
end
