module Questions::Concerns::AwardExtractor
  extend ActiveSupport::Concern

  private

  def extract_award_info(award_condition)
    award_id = award_lookup[award_condition]
    return nil unless award_id
    
    {
      condition: award_condition,
      award_id: award_id
    }
  end

  def award_lookup
    DataLookupHelper.award_lookup
  end
end
