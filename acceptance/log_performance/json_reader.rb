require 'json'

class JSONReader
  def self.json_file_to_hash(file_path)
    JSON.parse(File.read(file_path))
  end
end