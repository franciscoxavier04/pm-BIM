# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "rails_helper"

RSpec.describe EnterpriseEdition::BannerComponent, type: :component do
  let(:title) { "Some title" }
  let(:expected_title) { title }
  let(:description) { "Some description" }
  let(:expected_description) { description }
  let(:href) { "https://www.example.org" }
  let(:component_test_selector) { "op-enterprise-banner-some-enterprise-feature" }
  let(:features) { nil }
  let(:enforce_available_locales) { I18n.config.enforce_available_locales }
  let(:i18n_upsale) do
    {
      some_enterprise_feature: {
        title:,
        description:,
        features:
      }.compact
    }
  end
  let(:static_links) do
    {
      enterprise_docs: {
        some_enterprise_feature: {
          href:
        }
      }
    }
  end
  let(:translations) do
    {
      ee: {
        upsale: i18n_upsale
      },
      enterprise_features: {
        some_enterprise_feature: "Enterprise feature translation"
      }
    }
  end
  let(:component_args) { {} }

  let(:render_component) do
    render_inline(described_class.new(:some_enterprise_feature, **component_args))
  end

  let(:render_component_in_mo) do
    I18n.with_locale :mo do
      render_component
    end
  end

  before do
    allow(OpenProject::Static::Links)
      .to receive(:links)
            .and_return(static_links)

    I18n.config.enforce_available_locales = !enforce_available_locales

    I18n.backend.store_translations(
      :mo,
      translations
    )
  end

  after do
    I18n.backend.translations.delete(:mo)
    I18n.config.enforce_available_locales = enforce_available_locales
  end

  shared_examples_for "renders the component" do
    it "renders the component" do
      render_component_in_mo

      component = find_test_selector(component_test_selector)

      expect(component).to have_text(expected_title)
      expect(component).to have_text(expected_description)
      expect(component).to have_link("More information", href:)
    end
  end

  shared_examples_for "does not render the component" do
    it "does not render the component" do
      render_component_in_mo

      expect(page).not_to have_test_selector(component_test_selector)
      expect(page).to have_no_text("Enterprise feature translation")
      expect(page).to have_no_text(expected_title)
      expect(page).to have_no_text(expected_description)
      expect(page).to have_no_link(href:)
    end
  end

  it_behaves_like "renders the component"

  context "when feature is available", with_ee: %i[some_enterprise_feature] do
    it_behaves_like "does not render the component"
  end

  context "when banners are hidden" do
    before do
      allow(EnterpriseToken).to receive(:hide_banners?).and_return(true)
    end

    it_behaves_like "does not render the component"
  end

  context "when banner is dismissed" do
    let(:preference) { build_stubbed(:user_preference) }
    let(:user) { build_stubbed(:user, preference:) }
    let(:dismiss_key) { :some_enterprise_feature }
    let(:component_args) { { dismissable: true } }

    before do
      login_as(user)
      allow(preference)
        .to receive(:dismissed_banner?)
              .with(dismiss_key)
              .and_return(true)
    end

    it_behaves_like "does not render the component"

    context "when not dismissable" do
      let(:component_args) { { dismissable: false } }

      it_behaves_like "renders the component"
    end

    context "when using a custom dismiss_key" do
      let(:dismiss_key) { :foo }
      let(:component_args) { { dismiss_key:, dismissable: true } }

      it_behaves_like "does not render the component"
    end
  end

  context "without a title, but a description_html" do
    let(:i18n_upsale) do
      {
        some_enterprise_feature: {
          description_html: description
        }
      }
    end
    let(:expected_title) { "Enterprise feature translation" }

    it_behaves_like "renders the component"
  end

  context "without a title, but a description" do
    let(:i18n_upsale) do
      {
        some_enterprise_feature: {
          description:
        }
      }
    end
    let(:expected_title) { "Enterprise feature translation" }

    it_behaves_like "renders the component"
  end

  context "with a more specific title in the i18n file" do
    let(:i18n_upsale) do
      {
        some_enterprise_feature: {
          title:,
          description:
        }
      }
    end

    it_behaves_like "renders the component"
  end

  context "with a custom i18n_scope" do
    let(:translations) do
      {
        my: {
          custom: {
            upsale: {
              title: "Foo",
              description: "Bar"
            }
          }
        },
        enterprise_features: {
          some_enterprise_feature: "Enterprise feature translation"
        }
      }
    end
    let(:expected_title) { "Foo" }
    let(:expected_description) { "Bar" }
    let(:component_args) { { i18n_scope: "my.custom.upsale" } }

    it_behaves_like "renders the component"
  end

  context "without a description key in the i18n file" do
    let(:i18n_upsale) do
      {
        some_enterprise_feature: {}
      }
    end

    it "raises an error" do
      expect { render_component_in_mo }.to raise_error(I18n::MissingTranslationData)
    end
  end

  context "without a link key in the static_link file" do
    let(:static_links) do
      {
        enterprise_docs: {
          some_enterprise_feature: {}
        }
      }
    end

    it "raises an error" do
      expect { render_component_in_mo }.to raise_error(RuntimeError)
    end
  end
end
