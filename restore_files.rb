@ss_copy = File.expand_path(File.dirname(__FILE__))

puts "restore files"
file_ids = SS::File.all.pluck(:id)
file_ids.each do |id|
  file = SS::File.find(id) rescue nil
  next if file.nil?
  next if ::File.exists?(file.path)

  path = ::File.join(@ss_copy, "restore_files", "#{file.extname}.#{file.extname}")
  if ::File.exists?(path) && !::File.directory?(path)
    Fs.binwrite file.path, File.binread(path)
    puts "restore : #{file.filename}"
  else
    path = ::File.join(@ss_copy, "restore_files", "unknown")
    Fs.binwrite file.path, File.binread(path)
    puts "restore : unknown format #{file.extname} (#{file.filename})"
  end
end
