require 'pty'

# http://stackoverflow.com/q/10262235/1664216
# http://stackoverflow.com/a/1162850/1664216

module Runner

  def self.run(cwd, cmd, options)
    spinner_chars = [
      "\b/",
      "\b-",
      "\b\\",
      "\b|"
    ]

    begin
      Swerve.log_part("Running '#{cmd}'... ")
      PTY.spawn( "cd #{cwd}; #{cmd}" ) do |stdin, stdout, pid|
        begin
          # Do stuff with the output here. Just printing to show it works
          # stdin.each { |line| print line }
          ii = -1
          stdin.each { |line| print ' ' if ii == -1; ii = ii+1; print spinner_chars[ii % spinner_chars.length]}
        rescue Errno::EIO
          print "\b"
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
