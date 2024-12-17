module OpenProject::Storages::Patches::ReplaceReferencesServicePatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    private

    def rewrite_creator(from, to)
      super

      [::Storages::Storage,
       ::Storages::ProjectStorage,
       ::Storages::FileLink].each do |klass|
        klass.where(creator_id: from.id).update_all(creator_id: to.id)
      end
    end
  end
end
