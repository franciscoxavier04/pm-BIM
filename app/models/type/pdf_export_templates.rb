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

class Type::PdfExportTemplates
  Template = Data.define(:id, :label, :caption, :enabled)

  def initialize(model)
    @type = model
  end

  def list
    disabled = @type.export_templates_disabled || []
    templates = build_in_templates.map do |build_in_template|
      Template.new(**build_in_template, enabled: disabled.exclude?(build_in_template[:id]))
    end
    order = @type.export_templates_order || []
    return templates if order.empty?

    indexes = order.each_with_index.to_a.to_h
    templates.sort_by { |template| indexes[template.id] }
  end

  def list_enabled
    list.filter(&:enabled)
  end

  def find(template_id)
    build_in_template = build_in_templates.find { |t| t[:id] == template_id }
    if build_in_template
      disabled = @type.export_templates_disabled || []
      Template.new(**build_in_template, enabled: disabled.exclude?(build_in_template[:id]))
    end
  end

  def enable_all
    @type.export_templates_disabled = []
  end

  def disable_all
    @type.export_templates_disabled = build_in_templates.pluck(:id)
  end

  def toggle(template_id)
    disabled = @type.export_templates_disabled || []
    if disabled.include?(template_id)
      disabled.delete(template_id)
    else
      disabled.push(template_id)
    end
    @type.export_templates_disabled = disabled
  end

  def move(template_id, position)
    template_ids = @type.pdf_export_templates_for_type.map(&:id)
    prev_index = template_ids.find_index(template_id)
    template_ids.delete_at(prev_index) unless prev_index.nil?
    template_ids.insert(position, template_id)
    @type.export_templates_order = template_ids
  end

  private

  def build_in_templates
    ::WorkPackage::PDFExport::Templates::TEMPLATES
  end
end
