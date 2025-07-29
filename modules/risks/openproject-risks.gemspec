# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-risks"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject GmbH"]
  s.email       = ["info@openproject.com"]
  s.homepage    = "https://github.com/opf/openproject-risks"
  s.summary     = "Risk management module for OpenProject"
  s.description = "This module adds risk management capabilities to OpenProject, including risk work package types with impact, likelihood, and level attributes."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,frontend,lib,spec}/**/*"] + ["README.md"]
end
