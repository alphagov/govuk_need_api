require_relative '../../test_helper'

module Search
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
      @indexable_need = IndexableNeed.new(need)
    end

    should "return the need's ID" do
      assert_equal 123456, @indexable_need.need_id
    end

    should "present an indexable need" do
      presented_need = @indexable_need.present

      assert_equal 123456, presented_need[:need_id]
      assert_equal "Role", presented_need[:role]
      assert_equal "Goal", presented_need[:goal]
      assert_equal "Benefit", presented_need[:benefit]
      assert_equal ["org-1"], presented_need[:organisation_ids]
      assert_equal ["Criteria 1", "Criteria 2"], presented_need[:met_when]
      assert_equal ["Legislation 1", "Legislation 2"], presented_need[:legislation]
      assert_equal ["Evidence 1", "Evidence 2"], presented_need[:other_evidence]
    end

    should "only index free-text fields" do
      presented_need = @indexable_need.present

      assert_nil presented_need[:organisations]
      assert_nil presented_need[:justifications]
      assert_nil presented_need[:impact]
      assert_nil presented_need[:monthly_user_contacts]
      assert_nil presented_need[:monthly_site_views]
      assert_nil presented_need[:monthly_need_views]
      assert_nil presented_need[:monthly_searches]
      assert_nil presented_need[:currently_met]
    end

    should "expose a list of fields" do
      assert IndexableNeed.fields.any?
      IndexableNeed.fields.each do |field|
        assert field.respond_to?(:name)
        assert field.respond_to?(:type)
        assert field.respond_to?(:analyzed?)
        assert field.respond_to?(:include_in_all?)
      end
    end
  end
end
