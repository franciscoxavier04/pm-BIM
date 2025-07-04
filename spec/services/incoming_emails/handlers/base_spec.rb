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

RSpec.describe IncomingEmails::Handlers::Base do
  let(:user) { build_stubbed(:user) }
  let(:reference) { nil }
  let(:options) { {} }
  let(:plain_text_body) { "Test body" }

  subject do
    described_class.new(nil, user:, reference:, plain_text_body:, options:)
  end

  describe "#cleanup_body" do
    let(:plain_text_body) do
      "Subject:foo\nDescription:bar\n" \
        ">>> myserver.example.org 2016-01-27 15:56 >>>\n... (Email-Body) ..."
    end

    context "with regex delimiter" do
      before do
        allow(Setting).to receive(:mail_handler_body_delimiter_regex).and_return(">>>.+?>>>.*")
      end

      it "removes the irrelevant lines" do
        expect(subject.cleaned_up_text_body).to eq("Subject:foo\nDescription:bar")
      end
    end
  end
end
