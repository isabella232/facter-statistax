require_relative 'beaker'

class VMPooler < Beaker
  def initialize(platforms, user_home_path, env_vars, logger)
    super(platforms, user_home_path, env_vars, logger)
  end
end