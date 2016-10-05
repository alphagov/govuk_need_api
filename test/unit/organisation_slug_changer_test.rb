require 'test_helper'
require 'organisation_slug_changer'

class OrganisationSlugChangerTest < ActiveSupport::TestCase
  setup do
    @organisation = create(:organisation, slug: "organisation-1")

    @new_slug = 'new-slug'

    @slug_changer = OrganisationSlugChanger.new(
      @organisation.slug,
      @new_slug
    )
  end

  test 'it returns true on success' do
    assert @slug_changer.call
  end

  test 'it returns false if org does not exist' do
    slug_changer = OrganisationSlugChanger.new('non-existent-slug', 'new')
    assert_equal false, slug_changer.call
  end

  test 'it creates a new organisation with new slug and _id' do
    @slug_changer.call

    new_org = Organisation.where(slug: @new_slug).first

    assert_equal @new_slug, new_org.slug
    assert_equal @new_slug, new_org._id
  end

  test 'it copies over other attributes to the new organisation' do
    @slug_changer.call

    new_org = Organisation.where(slug: @new_slug).first

    attributes = [
      :name,
      :govuk_status,
      :abbreviation,
      :parent_ids,
      :child_ids
    ]

    attributes.each do |attribute|
      assert_equal new_org.send(attribute), @organisation.send(attribute)
    end
  end

  test 'it removes the old organisation' do
    @slug_changer.call

    assert_equal 0, Organisation.where(slug: @old_slug).count
    assert_equal 0, Organisation.where(_id: @old_slug).count
  end

  test 'it changes the organisation_slug of associated users' do
    user = create(:user, organisation_slug: @organisation.slug)

    @slug_changer.call

    assert_equal @new_slug, user.reload.organisation_slug
  end

  test 'it updates any needs' do
    need = create(:need, organisation_ids: [@organisation._id])

    @slug_changer.call

    assert_equal [@new_slug], need.reload.organisation_ids
  end

  test 'it records the need revision using an appropriate user' do
    need = create(:need, organisation_ids: [@organisation._id])

    @slug_changer.call

    expected_author = {
      "name" => "Data Migration",
      "email" => "govuk-maslow@digital.cabinet-office.gov.uk",
      "uid" => nil
    }

    assert_equal expected_author, need.reload.revisions.map(&:author).first
  end
end
