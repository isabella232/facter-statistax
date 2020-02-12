require 'open3'
require 'timeout'

module RunCommand
  def self.run_command(timeout_in_minutes = 1, env_vars = {}, command)
    @wait_thread = nil
    @output = ''
    begin
      Timeout.timeout(timeout_in_minutes * 60) do
        get_command_output(command, env_vars)
      end
    rescue Timeout::Error
      Process.kill('KILL', @wait_thread) if @wait_thread.alive?
      "Timed out! Did only:\n#{@output}"
    end
  end

  private_class_method def self.get_command_output(command, env_vars)
    Open3.popen2e(env_vars, command) do |_stdin, stdout_and_stderr, wait_thr|
      @wait_thread = wait_thr
      stdout_and_stderr.each do |line|
        @output << line
        puts line
      end
    end
    @output
  end

end

