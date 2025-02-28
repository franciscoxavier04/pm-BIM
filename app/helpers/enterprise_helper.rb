module EnterpriseHelper
  def write_augur_to_gon
    gon.augur_url = OpenProject::Configuration.enterprise_trial_creation_host
    gon.token_version = OpenProject::Token::VERSION
  end

  def write_trial_key_to_gon
    trial_key = Token::EnterpriseTrialKey.find_by(user_id: User.system.id)
    if trial_key
      gon.ee_trial_key = {
        value: trial_key.value,
        created: trial_key.created_at
      }
    end
  end

  def enterprise_token_plan_name(enterprise_token)
    if enterprise_token.respond_to?(:plan)
      <<~LABEL.squish
        #{I18n.t(enterprise_token.plan, scope: [:enterprise_plans])}
        (#{I18n.t('enterprise_plans.label_token_version')} #{enterprise_token.version})
      LABEL
    end
  end

  def enterprise_plan_additional_features(enterprise_token)
    (enterprise_token.try(:features) || [])
      .map { |feature| I18n.t(feature, scope: [:enterprise_features], default: feature.to_s.humanize) }
        .join(", ")
  end
end
