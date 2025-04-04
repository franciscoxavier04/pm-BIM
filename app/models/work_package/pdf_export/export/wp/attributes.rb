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

module WorkPackage::PDFExport::Export::Wp::Attributes
  def write_attributes!(work_package)
    work_package
      .type.attribute_groups
      .each do |group|
      if group.is_a?(Type::AttributeGroup)
        write_attributes_group(group, work_package)
      elsif group.is_a?(Type::QueryGroup)
        write_query_group(group, work_package)
      end
    end
  end

  private

  def write_long_text_field!(work_package, field_id)
    custom_value = work_package.custom_field_values
                               .find { |cv| cv.custom_field.id == field_id && cv.custom_field.formattable? }
    write_long_text_custom_field!(work_package, custom_value.value || "", custom_value.custom_field.name)
  end

  def write_long_text_custom_field!(work_package, markdown, label)
    write_optional_page_break
    write_long_text_custom_field_label(label)
    write_markdown_field_value(work_package, markdown)
  end

  def write_long_text_custom_field_label(label)
    with_margin(styles.wp_markdown_label_margins) do
      pdf.formatted_text([styles.wp_attributes_table_label.merge({ text: label })])
    end
  end

  def write_query_group(group, work_package)
    prepare_query_group(group, work_package)
    related_work_packages = group.query.results.work_packages
    write_group_title(group)
    if related_work_packages.empty?
      write_inline_hint("[No work packages]")
    else
      write_work_packages_table!(related_work_packages, group.query)
    end
  rescue Prawn::Errors::CannotFit
    write_inline_error("[#{I18n.t('export.errors.embedded_table_with_too_many_columns')}]")
  end

  def write_inline_hint(text)
    with_margin(styles.wp_table_margins) do
      pdf.formatted_text([styles.inline_hint.merge({ text: })])
    end
  end

  def write_inline_error(text)
    with_margin(styles.wp_markdown_label_margins) do
      pdf.formatted_text([styles.inline_error.merge({ text: })])
    end
  end

  def prepare_query_group(group, work_package)
    # QueryGroup are relative to our work package, so we need to adjust the filter
    group.query.filters.each do |filter|
      if filter.respond_to?(:has_templated_value?) && filter.has_templated_value?
        group.query.filters[0].values = [work_package.id]
      end
    end
  end

  def write_attributes_group(group, work_package)
    write_group_title(group)
    group_parts = group_attributes_group_parts(group, work_package)
    group_parts.each do |part|
      if part[:type] == :attribute
        write_attributes_group_table(part[:list], work_package)
      else
        part[:list].each do |cf|
          write_long_text_field!(work_package, cf.id)
        end
      end
    end
  end

  def write_attributes_group_table(list, work_package)
    rows = attributes_to_rows(list, work_package)
    return if rows.empty?

    with_margin(styles.wp_attributes_table_margins) do
      pdf.table(
        rows,
        column_widths: attributes_table_column_widths,
        cell_style: styles.wp_attributes_table_cell.merge({ inline_format: true })
      )
    end
  end

  def attributes_to_rows(list, work_package)
    list = attributes_to_column_entries(list, work_package)
             .map { |entry| entry.merge({ value: get_column_value_cell(work_package, entry[:name]) }) }
    form_config_group_to_column_entries_rows(list)
  end

  def attributes_to_column_entries(list, work_package)
    list.map do |form_key|
      form_key_to_column_entries(form_key.to_sym, work_package)
    end.flatten
  end

  def group_attributes_group_parts(group, work_package)
    current_part = { type: :attribute, list: [] }
    parts = [current_part]
    group.attributes.each do |form_key|
      if allowed_long_text_custom_field?(form_key, work_package)
        cf = form_key_to_custom_field(form_key)
        if current_part[:type] == :long_text
          current_part[:list] << cf
        else
          current_part = { type: :long_text, list: [cf] }
          parts << current_part
        end
      elsif current_part[:type] != :attribute
        current_part = { type: :attribute, list: [form_key] }
        parts << current_part
      else
        current_part[:list] << form_key
      end
    end
    parts
  end

  def allowed_long_text_custom_field?(form_key, work_package)
    return false unless CustomField.custom_field_attribute? form_key

    cf = form_key_to_custom_field(form_key)
    return false if cf.nil?

    cf.formattable? && custom_field_allowed(cf, work_package)
  end

  def write_group_title(group, with_hr: true)
    write_optional_page_break
    with_margin(styles.wp_attributes_group_label_margins) do
      pdf.formatted_text([styles.wp_attributes_group_label
                                .merge({ text: group.translated_key })])
      write_group_title_hr if with_hr
    end
  end

  def write_group_title_hr
    hr_style = styles.wp_attributes_group_label_hr
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
  end

  def form_config_group_to_column_entries_rows(list)
    nr = page_orientation_landscape? ? 4 : 2
    0.step(list.length - 1, nr).map do |i|
      Array.new(nr).each_with_index.map do |_, j|
        build_columns_table_cells(list[i + j])
      end.flatten
    end
  end

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0] # label | value
    widths = widths * (page_orientation_landscape? ? 4 : 2)
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def form_key_to_custom_field(form_key)
    id = form_key.to_s.sub("custom_field_", "").to_i
    CustomField.find_by(id:)
  end

  def custom_field_allowed(custom_field, work_package)
    custom_field.is_for_all? || work_package.project.work_package_custom_field_ids.include?(custom_field.id)
  end

  def form_key_custom_field_to_column_entries(form_key, work_package)
    cf = form_key_to_custom_field(form_key)
    return [] if cf.nil? || cf.formattable? || !custom_field_allowed(cf, work_package)

    [{ label: cf.name || form_key, name: form_key.to_s.sub("custom_field_", "cf_") }]
  end

  def form_key_to_column_entries(form_key, work_package)
    return [] if form_key == :bcf_thumbnail

    if CustomField.custom_field_attribute? form_key
      return form_key_custom_field_to_column_entries(form_key, work_package)
    end

    column_name = ::API::Utilities::PropertyNameConverter.to_ar_name(form_key, context: work_package)
    [column_entry(column_name)]
  end

  def column_entries(column_names)
    column_names.map { |key| column_entry(key) }
  end

  def column_entry(column_name)
    { label: WorkPackage.human_attribute_name(column_name), name: column_name }
  end

  def build_columns_table_cells(attribute_data)
    return ["", ""] if attribute_data.nil?

    # get work package attribute table cell data: [label, value]
    [
      pdf.make_cell(attribute_data[:label], styles.wp_attributes_table_label_cell),
      attribute_data[:value]
    ]
  end

  def get_column_value_cell(work_package, column_name)
    value = get_column_value(work_package, column_name)
    return get_id_column_cell(work_package, value) if column_name == :id
    return get_subject_column_cell(work_package, value) if column_name == :subject

    escape_tags(value)
  end
end
