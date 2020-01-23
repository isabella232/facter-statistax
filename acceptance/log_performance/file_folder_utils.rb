class FileFolderUtils
  def self.get_children_names(parent_folder_path)
    begin
      #all children who's name doesn't start with '.'
      Dir.entries(parent_folder_path).reject{|entry| entry =~ /^\.+/}
    rescue Errno::ENOENT
      puts "No #{parent_folder_path} folder found!"
      []
    end
  end

  def self.file_exists(file_path)
    File.file?(file_path)
  end

  def self.get_sub_file_paths_by_type(parent_folder, file_extension)
    Dir["#{parent_folder}/**/*.#{file_extension}"].select { |f| File.file? f }
  end
end