Rails.application.configure do
  config.view_component.previews.paths << Rails.root.join("spec/components/previews").to_s
  config.view_component.previews.default_layout = "component_preview"

  config.view_component.generate.preview = true
  config.view_component.generate.preview_path = Rails.root.join("spec/components/previews").to_s

  # Enable instrumentation (e.g., for AppSignal)
  config.view_component.instrumentation_enabled = true
end
