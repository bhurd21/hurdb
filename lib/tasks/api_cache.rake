namespace :api_cache do
  desc "Clear all cached API responses"
  task clear: :environment do
    cache_dir = Rails.root.join("tmp", "cache", "api_responses")
    
    if Dir.exist?(cache_dir)
      FileUtils.rm_rf(Dir.glob(File.join(cache_dir, "*.json")))
      puts "Cleared all cached API responses from #{cache_dir}"
    else
      puts "Cache directory doesn't exist: #{cache_dir}"
    end
  end

  desc "Show cache statistics"
  task stats: :environment do
    cache_dir = Rails.root.join("tmp", "cache", "api_responses")
    
    if Dir.exist?(cache_dir)
      files = Dir.glob(File.join(cache_dir, "*.json"))
      total_size = files.sum { |file| File.size(file) }
      
      puts "Cache Statistics:"
      puts "  Directory: #{cache_dir}"
      puts "  Total files: #{files.count}"
      puts "  Total size: #{(total_size / 1024.0).round(2)} KB"
      
      if files.any?
        puts "  Oldest file: #{File.mtime(files.min_by { |f| File.mtime(f) })}"
        puts "  Newest file: #{File.mtime(files.max_by { |f| File.mtime(f) })}"
      end
    else
      puts "Cache directory doesn't exist: #{cache_dir}"
    end
  end
end
