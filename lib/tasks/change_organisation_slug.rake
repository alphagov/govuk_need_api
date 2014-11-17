desc "Change an organisation slug.

It performs the following steps:
- changes the organisation slug
- changes the organisation_slug field of any users

It is one part of an inter-related set of steps which must be carefully
coordinated.

For reference:

https://github.com/alphagov/wiki/wiki/Changing-GOV.UK-URLs#changing-an-organisations-slug"

task :change_organisation_slug, [:old_slug, :new_slug] => :environment do |_task, args|
  logger = Logger.new(STDOUT)
  if args[:old_slug].blank? || args[:new_slug].blank?
    logger.error("Please specifiy [old_slug,new_slug] arguments")
    exit(1)
  end

  slug_changer = OrganisationSlugChanger.new(
    args[:old_slug],
    args[:new_slug],
    logger: logger,
  )

  exit(1) unless slug_changer.call
end
