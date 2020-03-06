class FailedCommand < StandardError
  def message
    "Command failed!"
  end
end
