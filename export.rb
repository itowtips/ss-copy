require 'fileutils'

@ss_copy = ::File.basename(File.expand_path(File.dirname(__FILE__)))
@output = ::File.join(File.expand_path(File.dirname(__FILE__)), "tmp", ::File.basename(Rails.root))

@site_fs = []
SS::Site.each do |site|
  @site_fs << ::File.join(site.path, "fs").to_s
end

@images = {}
ids = SS::File.pluck(:id)
ids.each do |id|
  file = SS::File.find(id) rescue nil
  next if file.nil?
  next if !file.image?
  @images[file.path] = file
  @images[file.thumb.path] = file.thumb
end

def copy_private(path)
  paths = Dir.glob("#{path}/**/*", File::FNM_DOTMATCH)
  paths = paths.map { |path| path.delete_suffix("/.") }.uniq

  # remove cache_store
  cache_store_path = ::File.join(path, "cache_store")
  paths = paths = paths.select do |path|
    path !~ /^#{cache_store_path}(\/|$)/ || ::File.basename(path) == ".keep"
  end

  # remove not images
  paths = paths = paths.select do |path|
    @images[path] || ::File.basename(path) == ".keep"
  end

  paths.each do |path|
    src = path
    dist = path.sub(/^#{Rails.root}/, @output)
    if File.directory?(src)
      FileUtils.mkdir_p(dist)
    else
      FileUtils.mkdir_p(File.dirname(dist))
      FileUtils.cp(src, dist)
    end
  end
end

def copy_public(path)
  paths = Dir.glob("#{path}/**/*", File::FNM_DOTMATCH)
  paths = paths.map { |path| path.delete_suffix("/.") }.uniq

  # remove site fs
  @site_fs.each do |fs|
    paths = paths.select do |path|
      path !~ /^#{fs}(\/|$)/ || ::File.basename(path) == ".keep"
    end
  end

  paths.each do |path|
    src = path
    dist = path.sub(/^#{Rails.root}/, @output)
    if File.directory?(src)
      FileUtils.mkdir_p(dist)
    else
      FileUtils.mkdir_p(File.dirname(dist))
      FileUtils.cp(src, dist)
    end
  end
end

FileUtils.rm_rf(@output)
FileUtils.mkdir(@output)

Dir.chdir(Rails.root)
Dir.children('.').sort.each do |file|
  path = ::File.join(Rails.root, file)
  next if file == @ss_copy
  next if file == "tmp"

  puts file
  case file
  when "public"
    copy_public(path)
  when "private"
    copy_private(path)
  else
    FileUtils.copy_entry(file, ::File.join(@output, file))
  end
end
