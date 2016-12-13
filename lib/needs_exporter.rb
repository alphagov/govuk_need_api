#encoding: utf-8
require 'gds_api/publishing_api_v2'
require 'csv'

class NeedsExporter
  def initialize
    @needs = Need.all
    @api_client = GdsApi::PublishingApiV2.new(Plek.find('publishing-api'))
  end

  def run
    @needs.each_with_index do |need, index|
      p "#{index}/#{@needs.count}"
      export(need)
    end
  end

private

  def export(need)
    snapshots = need.revisions.map { |nr| present_need_revision(nr)}
    @api_client.import(need.content_id, snapshots)
    links = present_links(need)
    @api_client.patch_links(need.content_id, links: links)
  end

  def present_need_revision(need_revision)
    {
      action: "Publish",
      payload: {
                title: need_revision.snapshot["benefit"],
                publishing_app: "Need-API",
                schema_name: "need",
                document_type: "need",
                rendering_app: "info-frontend",
                locale: "en",
                base_path: "/needs/#{slug(need_revision)}",
                routes: [{
                  path: "/needs/#{slug(need_revision)}",
                  type: "exact"
                }],
                details: present_details(need_revision.snapshot)
               }
    }
  end

  def present_details(snapshot)
    details = {}
    snapshot.each do |key, value|
      if should_not_be_in_details(key, value)
        next
      elsif key == "status"
        details["status"] = value["description"]
      elsif key.start_with?("yearly")
        details["#{key}"] = value.to_s
      else
        details["#{key}"] = value
      end
    end
    details
  end

  def present_links(need)
    links = {}
    need.attributes.each do |key, value|
      next unless is_a_link?(key) && value.present?
      if key == "organisation_ids"
        links["organisations"] = need.organisations.map(&:content_id)
      elsif key == "duplicate_of"
        links["related_items"] = related_needs(need).map(&:content_id)
      end
    end
    links
  end

  def is_a_link?(key)
    key == "organisation_ids" ||
      key == "duplicate_of"
  end

  def should_not_be_in_details(key, value)
    is_a_link?(key) ||
      value == nil ||
      key == "content_id" ||
      deprecated_fields.include?(key)
  end

  def slug(need_revision)
    need_revision.need.benefit.parameterize
  end

  def related_needs(need)
    Need.where(need_id: need.duplicate_of)
  end

  def deprecated_fields
    %w{monthly_user_contacts monthly_need_views currently_met in_scope out_of_scope_reason}
  end
end
