Gem::Specification.new do |s|
  s.name        = "risks"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Risk management"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "risks"
  s.metadata["rubygems_mfa_required"] = "true"
end
