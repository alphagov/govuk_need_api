class UpdateOrganisationSlug < Mongoid::Migration[4.2]
  def self.up
    organisation = Organisation.find_by(slug: "government-actuary-s-department")
    organisation.update_attributes({
      _id: "government-actuarys-department",
      slug: "government-actuarys-department"
    })
    needs_to_correct = Need.where(organisation_ids: ["government-actuary-s-department"])
    needs_to_correct.each do |n|
      n.organisation_ids=["government-actuarys-department"]
      n.save
    end
  end

  def self.down
    organisation =
      Organisation.find_by(slug: "government-actuary-s-department") ||
      Organisation.find_by(slug: "government-actuarys-department")
    organisation.update_attributes({
      _id: "government-actuary-s-department",
      slug: "government-actuary-s-department"
    })
    needs_to_correct =
    Need.where( organisation_ids: ["government-actuary-s-department"] ) ||
    Need.where( organisation_ids: ["government-actuarys-department"] )
    needs_to_correct.each do |n|
      n.organisation_ids=["government-actuarys-department"]
      n.save
    end
  end
end
