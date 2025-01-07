#-- copyright
#++

require "spec_helper"
require Rails.root.join("db/migrate/20250102161733_adds_position_cache_to_hierarchy_items.rb")

RSpec.describe AddsPositionCacheToHierarchyItems, type: :model do
  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

  it "backfills the position_cache value on already existing hierarchy items" do
    ActiveRecord::Migration.suppress_messages { described_class.new.down }

    root = service.generate_root(custom_field).value!
    anakin = service.insert_item(label: "luke", parent: root).value!
    chewie = service.insert_item(label: "chewbacca", parent: root).value!
    luke = service.insert_item(label: "luke", parent: anakin).value!
    leia = service.insert_item(label: "leia", parent: anakin).value!

    expect(root.self_and_descendants_preordered).to eq([root, anakin, luke, leia, chewie])

    ActiveRecord::Migration.suppress_messages { described_class.new.up }

    expect(root.reload.position_cache).to eq(125)
    expect(anakin.reload.position_cache).to eq(150)
    expect(luke.reload.position_cache).to eq(155)
    expect(leia.reload.position_cache).to eq(160)
    expect(chewie.reload.position_cache).to eq(175)
  end
end
