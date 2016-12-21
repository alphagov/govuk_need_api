#encoding: utf-8
require 'gds_api/publishing_api_v2'
require 'csv'

class NeedsExporter
  def initialize
    @needs = Need.all
    @api_client = GdsApi::PublishingApiV2.new(Plek.find('publishing-api'))
    @slugs = Set.new
  end

  def run
    @needs.each_with_index do |need, index|
      export(need, index)
    end
  end

private

  def export(need, index)
    slug = generate_slug(need)
    need_revisions = filter_need_revisions(need).compact
    snapshots = need_revisions.map { |nr| present_need_revision(nr, slug)}
    @api_client.import(need.content_id, snapshots)
    links = present_links(need)
    @api_client.patch_links(need.content_id, links: links)
    p "#{index}/#{@needs.count}"
    p "exported #{slug}"
  end

  def present_need_revision(need_revision, slug)
    {
       title: need_revision.snapshot["benefit"],
       publishing_app: "Need-API",
       schema_name: "need",
       document_type: "need",
       rendering_app: "info-frontend",
       locale: "en",
       base_path: "/needs/#{slug}",
       state: map_to_publishing_api_state(need_revision),
       routes: [{
         path: "/needs/#{slug}",
         type: "exact"
       }],
       details: present_details(need_revision.snapshot)
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

  def generate_slug(need)
    base_slug = need.benefit.parameterize
    n = 0
    slug = ""
    loop do
      slug = base_slug + suffix(n)
      break unless @slugs.include?(slug)
      n += 1
    end
    @slugs.add(slug)
    slug
  end

  def suffix(n)
    return "" if n == 0
    "-#{n}"
  end

  def filter_need_revisions(need)
    to_be_published = []

    need_revisions = need.revisions.sort_by(&:created_at)

    need_revisions.reverse_each do |need_revision|
      if is_proposed?(need_revision) || is_not_valid?(need_revision)
        to_be_published << need_revision unless draft_already_in_list?(to_be_published)
      elsif is_valid?(need_revision)
        to_be_published << need_revision
      end
    end
    to_be_published
  end

  def draft_already_in_list?(revisions_list)
    status_list = []
    revisions_list.each {|r| status_list << get_status(r)}
    status_list.include?("proposed") || status_list.include?("not valid")
  end

  def published_already_in_list?(revisions_list)
    status_list = []
    revisions_list.each {|r| status_list << get_status(r)}
    status_list.include?("valid") || status_list.include?("valid with conditions")
  end

  def is_proposed?(need_revision)
    get_status(need_revision) == "proposed"
  end

  def is_valid?(need_revision)
    get_status(need_revision) == "valid" || get_status(need_revision) == "valid with conditions"
  end

  def is_not_valid?(need_revision)
    get_status(need_revision) == "not valid"
  end

  def related_needs(need)
    Need.where(need_id: need.duplicate_of)
  end

  def deprecated_fields
    %w{monthly_user_contacts monthly_need_views currently_met in_scope out_of_scope_reason}
  end

  def get_status(need_revision)
    if includes_snapshot?(need_revision)
      need_revision.snapshot["status"]["description"]
    else
      need_revision.need.status.description
    end
  end

  def is_latest?(need_revision)
    all_revisions = need_revision.need.revisions
    all_revisions.select(&:created_at).max == need_revision
  end

  def includes_snapshot?(need_revision)
    need_revision.snapshot["status"] && need_revision.snapshot["status"]["description"]
  end

  def map_to_publishing_api_state(need_revision)
    if need_revision.duplicate_of.present? && status == "proposed"
      {
        name: "unpublished",
        type: "withdrawal"
      }
    elsif is_proposed?(need_revision) || is_invalid?(need_revision)
      "draft"
    elsif is_valid?(need_revision)
      return "superseded" if published_already_in_list?(need_revision.need.revisions)
      "published"
    else
      raise "status not recognised: #{get_status(need_revision)}"
    end
  end
end
