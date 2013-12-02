require_relative '../../test_helper'

class NeedSearchResultTest < ActiveSupport::TestCase

  def need_hash
    {
      need_id: 123456,
      role: "Role",
      goal: "Goal",
      benefit: "Benefit",
      organisation_ids: ["org-1", "org-2"],
      met_when: ["Criteria 1", "Criteria 2"],
      legislation: ["Legislation 1", "Legislation 2"],
      other_evidence: ["Evidence 1", "Evidence 2"],
    }
  end

  setup do
    Organisation.stubs(:find).with(["org-1", "org-2"]).returns([:foo, :bang])
    @need_result = Search::NeedSearchResult.new(need_hash)
  end

  should "present fields as methods" do
    assert_equal 123456, @need_result.need_id
    assert_equal "Role", @need_result.role
    assert_equal "Goal", @need_result.goal
    assert_equal "Benefit", @need_result.benefit
    assert_equal ["org-1", "org-2"], @need_result.organisation_ids
    assert_equal ["Criteria 1", "Criteria 2"], @need_result.met_when
    assert_equal ["Legislation 1", "Legislation 2"], @need_result.legislation
    assert_equal ["Evidence 1", "Evidence 2"], @need_result.other_evidence
  end

  should "include organisations" do
    assert_equal [:foo, :bang], @need_result.organisations
  end

  should "not search for an empty list of organisations" do
    Organisation.expects(:find).never
    need_result = Search::NeedSearchResult.new(need_hash.merge(organisation_ids: []))
    assert_equal [], need_result.organisations
  end

  should "be immutable" do
    assert_raises(TypeError) { @need_result.need_id = 12 }
  end
end
