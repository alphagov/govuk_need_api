require 'csv'

class OrganisationImporter
  attr_accessor :file

  def initialize(file)
    @file = file
  end

  def run
    CSV.foreach(file, :headers => true) do |row|
      create_organisation(row['name'], row['slug'])
    end
  end

  private
  def create_organisation(name, slug)
    organisation = Organisation.new(:name => name, :slug => slug)
    if organisation.save
      puts "  #{name} --> created"
    else
      puts "  #{name} --> skipped"
    end
  end
end
