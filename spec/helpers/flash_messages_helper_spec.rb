# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

require "spec_helper"

RSpec.describe FlashMessagesHelper do
  describe "#render_flash_messages" do
    subject { helper.render_flash_messages }

    shared_examples "rendering a banner" do |css_class, icon, text|
      it "applies the correct classes" do
        expect(subject).to have_css ".flash", class: css_class
      end

      it "renders an icon" do
        expect(subject).to have_octicon(icon)
      end

      it "renders banner text" do
        expect(subject).to have_text(text)
      end

      it "always returns HTML-safe strings" do
        expect(subject).to be_html_safe
      end
    end

    shared_examples "rendering nothing" do
      it "renders nothing" do
        expect(subject).to be_blank
      end

      it "always returns HTML-safe strings" do
        expect(subject).to be_html_safe
      end
    end

    context "with no flash messages" do
      it_behaves_like "rendering nothing"
    end

    context "with an :op_modal flash message" do
      before do
        flash[:op_modal] = { component: "ExampleComponent", parameters: {} }
      end

      it_behaves_like "rendering nothing"
    end

    context "with an :op_primer_flash flash message" do
      before do
        flash[:op_primer_flash] = { message: "zu deiner Information", scheme: :success }
      end

      it_behaves_like "rendering a banner", "flash-success", :"check-circle", "zu deiner Information"
    end

    context "with an :info flash message" do
      before do
        flash[:info] = "zu deiner Information" # rubocop:disable Rails/I18nLocaleTexts
      end

      it_behaves_like "rendering a banner", "flash", :bell, "zu deiner Information"
    end

    context "with a :notice flash message" do
      before do
        flash[:notice] = "For your information" # rubocop:disable Rails/I18nLocaleTexts
      end

      it_behaves_like "rendering a banner", "flash-success", :"check-circle", "For your information"
    end

    context "with a :success flash message" do
      before do
        flash[:success] = "Congratulazioni! Sei arrivato" # rubocop:disable Rails/I18nLocaleTexts
      end

      it_behaves_like "rendering a banner", "flash-success", :"check-circle", "Congratulazioni! Sei arrivato"
    end

    context "with a :warning flash message" do
      before do
        flash[:warning] = "You will be logged out!" # rubocop:disable Rails/I18nLocaleTexts
      end

      it_behaves_like "rendering a banner", "flash-warn", :alert, "You will be logged out!"
    end

    context "with an :error flash message" do
      before do
        flash[:error] = "A Moderat(ely) New Error" # rubocop:disable Rails/I18nLocaleTexts
      end

      it_behaves_like "rendering a banner", "flash-error", :stop, "A Moderat(ely) New Error"
    end
  end

  describe "#render_flash_modal" do
    subject { helper.render_flash_modal }

    context "with no flash messages" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with an :op_modal flash message" do
      let(:example_component) do
        Class.new(ApplicationComponent) do
          options :param1, :param2

          def self.name
            "ExampleComponent"
          end

          def call
            "__RENDERED VALUES: #{param1} #{param2}__".html_safe # rubocop:disable Rails/OutputSafety
          end
        end
      end

      before do
        flash[:op_modal] = { component: example_component, parameters: { param1: "A", param2: "B" } }
      end

      it "renders the specified component" do
        expect(subject).to eq "__RENDERED VALUES: A B__"
      end
    end
  end
end
