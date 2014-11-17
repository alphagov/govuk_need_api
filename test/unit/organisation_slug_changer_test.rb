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

  test 'it changes the organisation slug' do
    @slug_changer.call

    assert_equal @new_slug, @organisation.reload.slug
  end

  test 'it changes the organisation_slug of associated users' do
    user = create(:user, organisation_slug: @organisation.slug)

    @slug_changer.call

    assert_equal @new_slug, user.reload.organisation_slug
  end
end
