class FileFolderUtils
  def self.get_sub_folder_path(parent_folder_path)
    begin
      Dir.entries(parent_folder_path).select { |file| !File.directory?(file) }
    rescue Errno::ENOENT
      puts "No #{parent_folder_path} folder found!"
      []
    end
  end

  def self.file_exists(file_path)
    File.file?(file_path)
  end

  def self.get_subfile_paths_by_type(parent_folder, file_extension)
    Dir["#{parent_folder}/**/*.#{file_extension}"].select { |f| File.file? f }
  end
end