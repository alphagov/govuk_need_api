require 'gds_api/organisations'

class OrganisationImporter
  def run
    logger.info "Fetching all organisations from the Organisation API..."
    organisations = organisations_api.organisations.with_subsequent_pages.to_a
    logger.info "Loaded #{organisations.size} organisations"

    organisations.each do |organisation|
      create_or_update_organisation(organisation)
    end

    logger.info "Import complete"
  end

  private

  def create_or_update_organisation(organisation_from_api)
    child_ids = related_organisation_slugs(organisation_from_api.child_organisations)
    parent_ids = related_organisation_slugs(organisation_from_api.parent_organisations)

    organisation_atts = {
      :name => organisation_from_api.title,
      :slug => organisation_from_api.details.slug,
      :abbreviation => organisation_from_api.details.abbreviation,
      :govuk_status => organisation_from_api.details.govuk_status,
      :parent_ids => parent_ids,
      :child_ids => child_ids
    }

    existing_organisation = Organisation.where(slug: organisation_from_api.details.slug).first

    if existing_organisation.present?
      existing_organisation.update_attributes(organisation_atts)
      logger.info "Updated #{existing_organisation.name}"
    else
      Organisation.new(organisation_atts).save
      logger.info "Created #{organisation_atts[:name]}"
    end
  end

  def related_organisation_slugs(arr)
    arr.map do |a|
      a.id.split('/').last
    end
  end

  def logger
    @logger ||= build_logger
  end

  def build_logger
    output = case Rails.env
             when "development" then STDOUT
             when "test" then "/dev/null"
             when "production" then Rails.root.join("log", "organisation_import.json.log")
             end

    Logger.new(output).tap {|logger|
      logger.formatter = json_log_formatter if Rails.env.production?
    }
  end

  def json_log_formatter
    proc {|severity, datetime, progname, message|
      {
        "@message" => message,
        "@tags" => ["cron", "rake"],
        "@timestamp" => datetime.iso8601
      }.to_json + "\n"
    }
  end

  def organisations_api
    @api_client ||= GdsApi::Organisations.new(Plek.current.find('whitehall-admin'), ORGANISATIONS_API_CREDENTIALS)
  end
end
