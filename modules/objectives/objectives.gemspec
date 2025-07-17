Gem::Specification.new do |s|
  s.name        = "objectives"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Objectives Management"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "objectives"
  s.metadata["rubygems_mfa_required"] = "true"
end
