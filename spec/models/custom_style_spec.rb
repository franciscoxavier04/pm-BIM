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

RSpec.describe CustomStyle do
  describe "#current" do
    subject { CustomStyle.current }

    context "there is one in DB" do
      it "returns an instance" do
        CustomStyle.create
        expect(subject).to be_a CustomStyle
      end

      it "returns the same instance for subsequent calls" do
        CustomStyle.create
        first_instance = CustomStyle.current
        expect(subject).to be first_instance
      end
    end

    context "there is none in DB" do
      before do
        RequestStore.delete(:current_custom_style)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    shared_examples "removing an image from a custom style" do
      let(:image) { raise "define me!" }
      let(:custom_style) { create "custom_style_with_#{image}" }

      let!(:file_path) { custom_style.send(image).file.path }

      before do
        custom_style.send :"remove_#{image}"
      end

      it "deletes the file" do
        expect(File.exist?(file_path)).to be false
      end

      it "clears the file mount column" do
        expect(custom_style.reload.send(image).file).to be_nil
      end
    end

    describe "#remove_favicon" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "favicon" }
      end
    end

    describe "#remove_touch_icon" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "touch_icon" }
      end
    end

    describe "#remove_logo" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "logo" }
      end
    end

    describe "#remove_export_logo" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "export_logo" }
      end
    end

    describe "#remove_export_cover" do
      it_behaves_like "removing an image from a custom style" do
        let(:image) { "export_cover" }
      end
    end
  end
end
