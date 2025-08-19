# frozen_string_literal: true

# Auto-build js translations in dev mode
Rails.application.config.after_initialize do
  if Rails.env.development?
    require "i18n-js/listen"
    I18nJS.listen(locales_dir: Rails.root.glob("modules/**/config/locales") + [Rails.root.join("config/locales")])
  end
end
