#encoding: utf-8
require 'gds_api/publishing_api_v2'
require 'csv'

class NeedsExporter

  def initialize
    @needs = Need.all
    @api_client = GdsApi::PublishingApiV2.new(Plek.find('publishing-api'))
  end

  def run
    export(@needs[0])
  end

private

  def export(need)
    snapshots = need.revisions.map{ |nr| present_need_revision(nr)}
    @api_client.import(need.content_id, snapshots)
  end

  def present_need_revision(need_revision)
    {
      action: "Publish",
      payload: {
                title: need_revision_title(need_revision),
                publishing_app: "Need-API",
                schema_name: "need",
                document_type: "need",
                rendering_app: "info-frontend",
                locale: "en",
                base_path: "/a_path",
                routes: [{
                  path: "/a_path",
                  type: "exact"
                }],
                details: present_details(need_revision.snapshot)
               }
    }
  end

  def present_details(snapshot)
    details = {}
    snapshot.each do |key, value|
      if should_not_be_in_details(key,value)
        next
      elsif key == "status"
        details["status"]= value["description"]
      else
        details["#{key}"]=value
      end
    end
    details
  end

  def is_a_link?(key)
    key == "organisation_ids"
  end

  def should_not_be_in_details(key,value)
    is_a_link?(key) || value == nil
  end

end
