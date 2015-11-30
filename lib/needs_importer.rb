#encoding: utf-8

require 'csv'

class NeedsImporter
  attr_accessor :file

  def initialize(file)
    @file = file
    @counter = {imported: 0, failed: 0}
  end

  def run
    CSV.foreach(file, headers: true, encoding: "utf-8") do |row|
      save_row(row)
      print "."
    end
    puts "\n\n#{@counter[:imported]} rows were imported."
    puts "Failed to import #{@counter[:failed]} rows, recorded in #{file}.failed." if @counter[:failed] > 0
  end

  private

  def save_row(row)
    need = Need.new(need_hash(row))
    if need.save_as({name: "Need Importer"})
      @counter[:imported] += 1
    else
      record_failed_row(row)
    end
  rescue StandardError
    record_failed_row(row)
  end

  def record_failed_row(row)
    @counter[:failed] += 1
    File.open("#{file}.failed", "a") do |f|
      f.puts row.to_s
    end
  end

  def need_hash(row)
    need = {
      "role" => row['As a...'],
      "goal" => row['I need to...'],
      "benefit" => row['so that...'],
    }
    add(need, "organisation_ids", [row['Organisation Id']].compact)
    add(need, "met_when", met_when(row))
    add(need, "justifications", justifications(row))
    add(need, "impact", impact(row))
    add(need, "yearly_user_contacts", yearly_user_contacts(row))
    add(need, "yearly_need_views", yearly_need_views(row))
    add(need, "yearly_searches", yearly_searches(row))
    add(need, "yearly_site_views", yearly_site_views(row))
    add(need, "other_evidence", other_evidence(row))

    need
  end

  def add(need, key, value)
    need.merge!({key => value}) if value.present?
  end

  def met_when(row)
    (1..35).map { |i| row["It's done when the user... (#{i})"] }
      .select(&:present?)
      .map { |criteria| 'User ' + criteria }
  end

  def justifications(row)
    [].tap do |j|
      j << "It's something only government does" if row["it's something that only the government does"] ||
          row["it’s something that only the government does"]

      j << "The government is legally obliged to provide it" if row["there is clear demand for it from users or the government is legally obliged to provide it"]

      j << "It's inherent to a person's or an organisation's rights and obligations" if row["it's inherent to a person's or an organisation's rights and obligations"]
      j << "It's something that people can do or it's something people need to know before they can do something that's regulated by/related to government" if row["it's something that people can do or it's something people need to know before they can do something that's regulated by/related to government"] ||
          row["it's something that people can do or it's something people need to know before they can do something that's regulated by / related to the government"]

      j << "There is clear demand for it from users" if row["there is clear demand for it from users or the government is legally obliged to provide it"]

      j << "It's something the government provides/does/pays for" if row["it's something the government provides, does or pays for"]
      j << "It's straightforward advice that helps people to comply with their statutory obligations" if row["it's straightforward advice that helps people to comply with their statutory obligations or provides certain kinds of advice and support to businesses, but excludes general life or business advice that is provided by third parties"]
    end
  end

  def impact(row)
    impacts = {
      "Endangers the health of individuals" => "Endangers people",
      "Endangers People" => "Endangers people",
      "Has serious consequences for your users and/or their customers" => "Has serious consequences for your users and/or their customers",
      "Has serious consequences for the day-to-day lives of your users" => "Has serious consequences for your users and/or their customers",
      "Has consequences for the majority of your users" => "Has consequences for the majority of your users",
      "Has consequences for the majority of your users." => "Has consequences for the majority of your users",
      "Noticed by the average member of the public" => "Noticed by the average member of the public",
      "Noticed only by an expert audience" => "Noticed only by an expert audience",
      "No impact" => "No impact",
    }

    impact_cell = "What would be the impact on users if GOV.UK failed to meet this need?"
    impacts[row[impact_cell]]
  end

  def yearly_user_contacts(row)
    yearly_value(row["Number of contacts related to user need"])
  end

  def yearly_need_views(row)
    yearly_value(row["Number of pageviews related to this user need"])
  end

  def yearly_searches(row)
    yearly_value(row["Number of search terms related to this user need"])
  end

  def yearly_site_views(row)
    yearly_value(row["raw pageviews (numeric only)"])
  end

  def yearly_value(val)
    Integer(val) if val
  end

  def other_evidence(row)
    row["Evidence for need"]
  end
end
