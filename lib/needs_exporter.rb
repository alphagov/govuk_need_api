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
      if need.benefit.parameterize == 'i-can-delay-paying-fuel-duty'
        export(need, index)
      end
    end
  end

private

  def export(need, index)
    slug = generate_slug(need)
    need_revision_groups = need_revision_groups(need.revisions)
    snapshots = need_revision_groups.map { |nrg| present_need_revision_group(nrg, slug)}
    @api_client.import(need.content_id, snapshots)
    links = present_links(need)
    @api_client.patch_links(need.content_id, links: links)
    p "#{index}/#{@needs.count}"
    p "exported #{slug}"
  end

  def present_need_revision_group(need_revision_group, slug)
    states = need_revision_group.map do |nr|
      map_to_publishing_api_state(nr, slug)
    end

    {
       title: need_revision_group[0].snapshot["benefit"],
       publishing_app: "need-api",
       schema_name: "need",
       document_type: "need",
       rendering_app: "info-frontend",
       locale: "en",
       base_path: "/needs/#{slug}",
       states: states,
       routes: [{
         path: "/needs/#{slug}",
         type: "exact"
       }],
       details: present_details(need_revision_group[0].snapshot)
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

  def need_revision_groups(need_revisions)
    need_revisions.inject([]) do |array, revision|
      next [[revision]] if array == []

      valid_transitions = [
        ["proposed", "proposed"],
        ["proposed", "valid"],
        ["proposed", "not valid"],
        ["valid", "not valid"]
      ]

      if valid_transitions.include?([array.last.last.snapshot["status"]["description"], revision.snapshot["status"]["description"]])
        array.last << revision
      else
        array << [revision]
      end
      array
    end
  end

  def map_to_publishing_api_state(need_revision, slug)
    if need_revision["duplicate_of"].present? && is_valid?(need_revision)
      {
        name: "unpublished",
        type: "withdrawal",
        date: need_revision["created_at"],
        explanation: "This need is a duplicate_of the need [#{need_revision.need.benefit}](/needs/#{slug})"
      }
    elsif is_proposed?(need_revision)
      {
        name: "draft",
        date: need_revision["created_at"]
      }
    elsif is_not_valid?(need_revision)
      {
        name: "unpublished",
        type: "withdrawal",
        date: need_revision["created_at"],
        explanation: "Thing."
      }
    elsif is_valid?(need_revision)
      {
        name: "published",
        date: need_revision["created_at"]
      }
    else
      raise "status not recognised: #{get_status(need_revision)}"
    end
  end
end
