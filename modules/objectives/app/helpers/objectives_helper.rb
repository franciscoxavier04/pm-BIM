module ObjectivesHelper
  def key_result_percentage(work_package)
    raise ArgumentError, "Work package must be of type Key Result" unless work_package.type == BmdsHackathon::References.key_result_type

    target = work_package.typed_custom_value_for(BmdsHackathon::Objectives.target_cf)
    current = work_package.typed_custom_value_for(BmdsHackathon::Objectives.current_cf)

    return 0 if target.nil? || target.zero?

    (current.to_f / target) * 100
  end
end
