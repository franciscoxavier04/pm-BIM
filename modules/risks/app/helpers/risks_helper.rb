module RisksHelper
  def risk_level_options(level_cf, range:)
    values =
      case range
      when :low
        (1..6)
      when :medium
        (6..15)
      when :high
        (16..25)
      else
        raise ArgumentError, "Invalid range specified"
      end

    level_cf
      .custom_options
      .select { |co| co.value.to_i.in?(values) }
  end

  def get_risk_level(work_package)
    risk_likelihood_cf = BmdsHackathon::References.risk_likelihood_cf
    risk_impact_cf = BmdsHackathon::References.risk_impact_cf
    risk_level_cf = BmdsHackathon::References.risk_level_cf

    likelihood = work_package.custom_value_for(risk_likelihood_cf)
    impact = work_package.custom_value_for(risk_impact_cf)

    likelihood_option = risk_likelihood_cf.custom_options.find { |co| co.id == likelihood.value.to_i }
    impact_option = risk_impact_cf.custom_options.find { |co| co.id == impact.value.to_i }

    return unless likelihood_option && impact_option

    value = likelihood_option.value.to_i * impact_option.value.to_i
    risk_level_cf.custom_options.find { |co| co.value.to_i == value }
  end
end
