require 'pty'

# http://stackoverflow.com/q/10262235/1664216
# http://stackoverflow.com/a/1162850/1664216

module Runner

  def self.run(cwd, cmd, options)
    options[:fork] ||= false
    options[:verbose] ||= false

    full_command = <<-FULL_COMMAND
      export PATH="/opt/rbenv/bin:$PATH"; 
      cd #{cwd}; 
      eval "$(rbenv init -)"; 
      rbenv shell --unset;
      test -e #{cwd}/.ruby-version && rbenv shell `cat #{cwd}/.ruby-version`;
      #{cmd}
    FULL_COMMAND

    if options[:verbose]
      puts "Full command:\n #{full_command}"
    end

    if options[:fork]
      Swerve.log_part("Running '#{cmd}' in a separate process... ")
      fork { `#{full_command}` }
    else

      spinner_chars = [
        "\b/",
        "\b-",
        "\b\\",
        "\b|"
      ]

      begin
        Swerve.log_part("Running '#{cmd}'... ")
        PTY.spawn( full_command ) do |stdin, stdout, pid|
          begin
            # Do stuff with the output here. Just printing to show it works
            if options[:verbose]
              stdin.each { |line| print line }
            else
              ii = -1
              stdin.each { |line| print ' ' if ii == -1; ii = ii+1; print spinner_chars[ii % spinner_chars.length]}
            end
          rescue Errno::EIO
            print "\b" if !options[:verbose]
            # puts "Errno:EIO error, but this probably just means " +
            #       "that the process has finished giving output"
          end
        end
        Swerve.log("done!")
      rescue PTY::ChildExited
        raise StandardError, "an error occured when running #{cmd}" if options[:errors_are_fatal]
      end

    end
  end

end
