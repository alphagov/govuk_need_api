class NeedStatusPresenter
  def initialize(need_status)
    @need_status = need_status
  end

  def as_json
    @need_status.present? ? @need_status.attributes.except("_id") : nil
  end
end
