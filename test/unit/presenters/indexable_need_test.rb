require_relative '../../test_helper'

class IndexableNeedTest < ActiveSupport::TestCase
  setup do
    need = OpenStruct.new(
      need_id: 123456,
      role: "Role",
      goal: "Goal",
      benefit: "Benefit",
      organisation_ids: ["org-1"],
      met_when: ["Criteria 1", "Criteria 2"],
      legislation: ["Legislation 1", "Legislation 2"],
      other_evidence: ["Evidence 1", "Evidence 2"],
      justifications: ["Justification 1"],
      impact: "impact",
      monthly_user_contacts: 1000,
      monthly_site_views: 1000,
      monthly_need_views: 1000,
      monthly_searches: 1000,
      currently_met: false
    )
    @indexable_need = IndexableNeed.new(need).present
  end

  should "present an indexable need" do
    assert_equal 123456, @indexable_need[:need_id]
    assert_equal "Role", @indexable_need[:role]
    assert_equal "Goal", @indexable_need[:goal]
    assert_equal "Benefit", @indexable_need[:benefit]
    assert_equal ["org-1"], @indexable_need[:organisation_ids]
    assert_equal ["Criteria 1", "Criteria 2"], @indexable_need[:met_when]
    assert_equal ["Legislation 1", "Legislation 2"], @indexable_need[:legislation]
    assert_equal ["Evidence 1", "Evidence 2"], @indexable_need[:other_evidence]
  end

  should "only index free-text fields" do
    assert_nil @indexable_need[:organisations]
    assert_nil @indexable_need[:justifications]
    assert_nil @indexable_need[:impact]
    assert_nil @indexable_need[:monthly_user_contacts]
    assert_nil @indexable_need[:monthly_site_views]
    assert_nil @indexable_need[:monthly_need_views]
    assert_nil @indexable_need[:monthly_searches]
    assert_nil @indexable_need[:currently_met]
  end
end
