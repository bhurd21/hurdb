require 'digest'
require 'fileutils'

class ApiController < ApplicationController
  include ApiHelper
  
  allow_unauthenticated_access only: %i[ imgrid ]
  
  def imgrid
    # Restrict to only accept 'questions' parameter
    sanitized_params = params.permit(:questions)
    
    questions = ingest_questions_param
    
    # Try to get cached response first
    cached_response = get_cached_response(questions)
    if cached_response
      render json: cached_response
      return
    end
    
    # Process queries and cache the result
    results = process_queries(questions)
    response_data = { suggestions: results }
    
    cache_response(questions, response_data)
    
    render json: response_data
  end

  private

  # Override params to use only sanitized parameters
  def params
    @sanitized_params ||= super.permit(:questions)
  end

  # Generate cache filename from questions JSON
  def cache_filename(questions)
    # Use the raw JSON as filename (safe characters only)
    questions_json = questions.to_json
    # Replace unsafe filename characters with underscores
    safe_filename = questions_json.gsub(/[^a-zA-Z0-9\-_]/, '_')
    # Truncate if too long and add timestamp prefix to avoid collisions
    if safe_filename.length > 200
      safe_filename = safe_filename[0..200]
    end
    "#{safe_filename}.json"
  end

  # Get cache file path
  def cache_file_path(questions)
    filename = cache_filename(questions)
    Rails.root.join("tmp", "cache", "api_responses", filename)
  end

  # Ensure cache directory exists
  def ensure_cache_directory
    cache_dir = Rails.root.join("tmp", "cache", "api_responses")
    FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
  end

  # Check if cache file is fresh (less than 1 month old)
  def cache_fresh?(file_path)
    return false unless File.exist?(file_path)
    File.mtime(file_path) > 1.month.ago
  end

  # Get cached response if available and fresh
  def get_cached_response(questions)
    return nil if questions.empty?

    file_path = cache_file_path(questions)
    Rails.logger.info "Checking cache file: #{file_path}"
    
    if cache_fresh?(file_path)
      begin
        cached_data = JSON.parse(File.read(file_path))
        Rails.logger.info "Cache HIT for questions: #{questions}"
        return cached_data
      rescue => e
        Rails.logger.warn "Failed to read cache file #{file_path}: #{e.message}"
        return nil
      end
    else
      Rails.logger.info "Cache MISS (stale or not found) for questions: #{questions}"
      return nil
    end
  end

  # Cache the response to file
  def cache_response(questions, response_data)
    return if questions.empty?

    begin
      ensure_cache_directory
      file_path = cache_file_path(questions)
      File.write(file_path, response_data.to_json)
      Rails.logger.info "Cached response to #{file_path} for questions: #{questions}"
    rescue => e
      Rails.logger.warn "Failed to cache response: #{e.message}"
      # Don't raise - caching is optional
    end
  end
end
