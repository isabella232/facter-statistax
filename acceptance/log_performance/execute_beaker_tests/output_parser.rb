require 'set'

module OutputParser
  @error_tokens = [
      'retrying in',
      'command not found',
      'invalidurierror',
      'timed out',
      'Failed while running the pre_suite suite',
      'Failed while running the tests suite',
      'NoMethodError',
      'ERROR Facter',
      'ERROR:  Gemspec file not found:'
  ]

  def self.errors?(data)
    errors = extract_errors(data)
    if errors.empty?
      [false, '']
    else
      [true, errors.to_a]
    end
  end

  private_class_method def self.extract_errors(data)
    # data needs to be encoded because you never know what you get from different vms
    data.encode!('UTF-8', invalid: :replace, undef: :replace)
    errors = Set.new
    @error_tokens.each do |error|
      # Match substring that contains the error token and is between [<time>] and [<time>]
      # used 'i' to ignore case
      data.scan(/[^\[]*#{error}[^\[]*/i) do |entire_error|
        errors << entire_error
      end
    end
    errors
  end

end

