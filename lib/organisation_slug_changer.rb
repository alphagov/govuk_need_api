class OrganisationSlugChanger
  def initialize(old_slug, new_slug, options = {})
    @old_slug = old_slug
    @new_slug = new_slug
    @logger = options[:logger] || Logger.new(nil)
  end

  def call
    if organisation.present?
      logger.info "Updating slug for organisation tag '#{organisation.slug}'"
      change_organisation_slug
      true
    else
      logger.info "No organisation found with slug '#{old_slug}'"
      false
    end
  end

  def change_organisation_slug
    create_new_organisation
    update_associated_needs
    update_associated_users
    destroy_original_organisation
  end

private
  attr_reader(
    :old_slug,
    :new_slug,
    :logger,
  )

  def organisation
    @organisation ||= Organisation.where(slug: old_slug).first
  end

  def associated_users
    User.where(organisation_slug: old_slug)
  end

  def update_associated_users
    associated_users.each do |user|
      user.organisation_slug = new_slug
      user.save!
      logger.info "   -> Changed organisation_slug of user '#{user.name}' (uid #{user.uid}) - '#{old_slug}' => '#{user.organisation_slug}'"
    end
  end

  def create_new_organisation
    new_attributes = organisation.attributes.slice(
      "name",
      "abbreviation",
      "govuk_status",
      "parent_ids",
      "child_ids"
    )
    new_organisation = Organisation.create(new_attributes.merge(slug: new_slug))
    logger.info "Created clone organisation with new slug '#{new_slug}'"
  end

  def associated_needs
    Need.where(organisation_ids: old_slug)
  end

  def update_associated_needs
    associated_needs.each do |need|
      update_organisation_id_of_need(need)
      reindex_need_in_search(need)
    end
  end

  def update_organisation_id_of_need(need)
    need.organisation_ids = need.organisation_ids - [old_slug] + [new_slug]
    need.save!
    logger.info "   -> Changed organisation_id of need '#{need._id}'"
  end

  def reindex_need_in_search(need)
    GovukNeedApi.indexer.index(Search::IndexableNeed.new(need))
    logger.info "   -> Reindexed need '#{need._id}'"
  rescue Search::Indexer::IndexingFailed => e
    logger.error "   -> Reindexing need '#{need._id}' failed due to #{e}"
  end

  def destroy_original_organisation
    organisation.destroy
    logger.info "Destroyed original organisation with slug '#{old_slug}'"
  end
end
