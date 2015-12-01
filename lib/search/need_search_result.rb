module Search
  # A wrapper around a result hash returned from elasticsearch, which makes it
  # look like a Need instance, so we can pass it into a BasicNeedPresenter.
  class NeedSearchResult < OpenStruct
    attr_reader :organisations

    def initialize(hash)
      super(hash)
      @organisations = fetch_organisations
      freeze
    end

    def fetch_organisations
      # NOTE: this will silently omit organisation IDs that don't correspond to
      # organisations, but we expect organisation IDs to be permanent and
      # unchanging. If this changes, we'll have to deal with it here.
      if organisation_ids.blank?
        []
      else
        Organisation.find(organisation_ids)
      end
    end
  end
end
