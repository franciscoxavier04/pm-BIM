# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::AttributeGroups::Transformer do
  subject(:transformer) { described_class.new(groups: raw_groups, user: user) }

  let(:user) { double("User") }

  describe "#call" do
    context "when groups are empty" do
      let(:raw_groups) { [] }

      it "returns an empty array" do
        expect(transformer.call).to eq([])
      end
    end

    context "when given a regular attribute group with key" do
      let(:raw_groups) do
        [
          {
            "name" => "Custom",
            "key" => "custom",
            "type" => "attribute",
            "attributes" => [
              { "key" => "custom_field_1" },
              { "key" => "custom_field_2" }
            ]
          }
        ]
      end

      it "returns transformed group with symbolized key and attribute keys" do
        expect(transformer.call).to eq([
                                         [:custom, ["custom_field_1", "custom_field_2"]]
                                       ])
      end
    end

    context "when group has no key" do
      let(:raw_groups) do
        [
          {
            "name" => "General Info",
            "type" => "attribute",
            "attributes" => [
              { "key" => "subject" }
            ]
          }
        ]
      end

      it "uses name as group name" do
        expect(transformer.call).to eq([
                                         ["General Info", ["subject"]]
                                       ])
      end
    end

    context "when given a query group with valid JSON" do
      let(:query_json) do
        {
          "_links" => {
            "columns" => [{ "href" => "/api/v3/queries/columns/id" }]
          },
          "filters" => [],
          "groupBy" => nil,
          "sortBy" => [],
          "name" => "Some query"
        }.to_json
      end

      let(:raw_groups) do
        [
          {
            "name" => "Embedded Table",
            "type" => "query",
            "query" => query_json
          }
        ]
      end

      let(:query_instance) { double("Query") }

      before do
        allow(User).to receive(:system).and_return(double("SystemUser"))
        allow(Query).to receive(:new_default).and_return(query_instance)

        allow(query_instance).to receive(:extend)
        allow(query_instance).to receive(:change_by_system).and_yield
        allow(query_instance).to receive(:user=)
        allow(query_instance).to receive(:show_hierarchies=)

        allow(API::V3::UpdateQueryFromV3ParamsService).to receive(:new)
          .and_return(
            double("UpdateQueryService", call: double("ServiceResult", success?: true))
          )
      end

      it "returns a group with a Query instance" do
        result = transformer.call
        name, entries = result.first

        expect(name).to eq("Embedded Table")
        expect(entries.first).to eq(query_instance)
      end
    end

    context "when given a query group with invalid JSON" do
      let(:raw_groups) do
        [
          {
            "name" => "Broken",
            "type" => "query",
            "query" => "not a json"
          }
        ]
      end

      it "raises JSON::ParserError" do
        expect { transformer.call }.to raise_error(JSON::ParserError)
      end
    end
  end
end
