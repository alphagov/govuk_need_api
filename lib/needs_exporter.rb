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
                base_path: "/a_path",
                routes: [{
                  path: "/a_path",
                  type: "exact"
                }],
                details: need_revision.snapshot
               }
    }
  end

end
