class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index privacy_policy unsolvable_cell_notice substack_article resume ]
  
  def index
  end
  
  def privacy_policy
    @last_updated = get_last_updated_for_article('privacy_policy')
  end

  def unsolvable_cell_notice
    @last_updated = get_last_updated_for_article('unsolvable_cell_notice')
  end

  def substack_article
    @last_updated = get_last_updated_for_article('substack_article', ['article_how_to.mov', 'immaculate_grid_puzzle_example.png'])
  end

  def resume
    @last_updated = get_last_updated_for_article('resume', ['resume.pdf'])
  end

  private

  def get_last_updated_for_article(page_name, asset_files = [])
    files_to_check = []
    
    # Add the HTML template file
    template_path = Rails.root.join('app', 'views', 'home', "#{page_name}.html.erb")
    files_to_check << template_path if File.exist?(template_path)
    
    # Add any asset files
    asset_files.each do |asset_file|
      asset_path = Rails.root.join('app', 'assets', 'images', asset_file)
      files_to_check << asset_path if File.exist?(asset_path)
    end
    
    return nil if files_to_check.empty?
    
    # Find the most recent modification time
    latest_time = files_to_check.map { |file| File.mtime(file) }.max
    latest_time.strftime("%b %d, %Y")
  end
end