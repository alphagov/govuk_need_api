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
    update_organisation_slug
    update_associated_users
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

  def update_organisation_slug
    organisation.update_attributes!(slug: new_slug)
    logger.info "Changed organisation slug '#{old_slug}' => '#{new_slug}'"
  end
end
