#encoding: utf-8
require 'gds_api/publishing_api_v2'
require 'csv'

class NeedsExporter
  def initialize
    @needs = Need.all
    @api_client = GdsApi::PublishingApiV2.new(
      Plek.find('publishing-api'),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
      timeout: 30
    )
    @slugs = Set.new
  end

  def run
    count = @needs.count
    @needs.order_by(:_id.asc).each_with_index do |need, index|
      export(need, index, count)
    end
  end

private

  def export(need, index, count)
    slug = generate_slug(need)
    need_revision_groups = need_revision_groups(need.revisions.sort_by(&:created_at))
    snapshots = need_revision_groups.map { |nrg| present_need_revision_group(need.id, nrg, slug) }
    compute_superseded_needs(snapshots)
    @api_client.import(need.content_id, "en", snapshots)
    links = present_links(need)
    @api_client.patch_links(need.content_id, links: links)

    padding = Math.log10(count).ceil
    puts format("%#{padding}d/#{count} exported #{slug}", index + 1)
  end

  def present_need_revision_group(need_id, need_revision_group, slug)
    states = need_revision_group.map do |nr|
      map_to_publishing_api_state(nr, slug)
    end

    last_snapshot = need_revision_group.last.snapshot
    role, goal, benefit =
      last_snapshot.values_at("role", "goal", "benefit").map(&:strip)

    {
       title: "As a #{role}, I need to #{goal}, so that #{benefit} (#{need_id})",
       publishing_app: "need-api",
       schema_name: "need",
       document_type: "need",
       rendering_app: "info-frontend",
       base_path: "/needs/#{slug}",
       states: states,
       routes: [{
         path: "/needs/#{slug}",
         type: "exact"
       }],
       details: present_details(need_revision_group.last)
    }
  end

  def compute_superseded_needs(snapshots)
    last_not_superseded = nil
    snapshots.reverse_each do |snapshot|
      # Every state that isn't published or draft is superseded.
      if last_not_superseded.nil?
        if %w(published unpublished).include?(snapshot[:states].last[:name])
          last_not_superseded = snapshot
        end
      else
        snapshot[:states] << { name: "superseded" }
      end
    end
  end

  def present_details(need_revision)
    details = {}
    need_revision.snapshot.each do |key, value|
      if should_not_be_in_details(key, value)
      else
        details[key.to_s] = value
      end
    end
    details.merge("need_id" => need_revision.need_id)
  end

  def present_links(need)
    links = {}
    need.attributes.each do |key, value|
      next unless is_a_link?(key) && value.present?
      if key == "organisation_ids"
        links["organisations"] = need.organisations.map(&:content_id)
      end
    end
    links
  end

  def is_a_link?(key)
    key == "organisation_ids"
  end

  def should_not_be_in_details(key, value)
    is_a_link?(key) ||
      value == nil ||
      key == "content_id" ||
      deprecated_fields.include?(key)
  end

  def generate_slug(need)
    base_slug = need.goal.parameterize
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
    return "" if n.zero?
    "-#{n}"
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

  def deprecated_fields
    %w{status monthly_user_contacts monthly_need_views currently_met in_scope out_of_scope_reason duplicate_of}
  end

  def get_status(need_revision)
    if snapshot_includes_status?(need_revision)
      need_revision.snapshot["status"]["description"]
    else
      "proposed" # Old revisions don't have a status, so just use "proposed"
    end
  end

  def snapshot_includes_status?(need_revision)
    need_revision.snapshot["status"] && need_revision.snapshot["status"]["description"]
  end

  def need_revision_groups(need_revisions)
    need_revisions.inject([]) do |array, revision|
      next [[revision]] if array == []

      valid_transitions = [
        %w(proposed proposed),
        %w(proposed valid),
        %w(proposed not\ valid),
        %w(valid not\ valid)
      ]

      if valid_transitions.include?([get_revision_snapshot_status(array.last.last.snapshot), get_revision_snapshot_status(revision.snapshot)])
        array.last << revision
      else
        array << [revision]
      end
      array
    end
  end

  def get_revision_snapshot_status(snapshot)
    # Some revisions are so old that they don't have a status attribute,
    # so mark them as proposed.
    if snapshot["status"].nil?
      "proposed"
    else
      snapshot["status"]["description"]
    end
  end

  def map_to_publishing_api_state(need_revision, _slug)
    if need_revision.snapshot["duplicate_of"].present?
      begin
        duplicate_need_id = need_revision.snapshot["duplicate_of"]
        duplicate_content_id = Need.find(duplicate_need_id).content_id
        {
          name: "unpublished",
          type: "withdrawal",
          date: need_revision["created_at"],
          explanation: "This need is a duplicate of: [embed:link:#{duplicate_content_id}]"
        }
      rescue Mongoid::Errors::DocumentNotFound
        {
          name: "unpublished",
          type: "withdrawal",
          date: need_revision["created_at"],
          explanation: "This need is a duplicate of an unknown need (#{duplicate_need_id})"
        }
      end
    elsif is_proposed?(need_revision)
      {
        name: "draft",
        date: need_revision["created_at"]
      }
    elsif is_not_valid?(need_revision)
      bulleted_reasons =
        need_revision.snapshot["status"]["reasons"].map { |x| "* #{x}\n" }.join
      explanation = "This need is not valid because:\n\n#{bulleted_reasons}"

      {
        name: "unpublished",
        type: "withdrawal",
        date: need_revision["created_at"],
        explanation: explanation
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
