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
end
