module WorkPackage::PDFExport::Export::AttributesByForm
  def write_attributes_tables!(work_package)
    rows = attribute_table_rows(work_package)
    return if rows.empty?

    with_margin(styles.wp_attributes_table_margins) do
      pdf.table(
        rows,
        column_widths: attributes_table_column_widths,
        cell_style: styles.wp_attributes_table_cell.merge({ inline_format: true })
      )
    end
  end

  private

  def attributes_table_column_widths
    # calculate fixed work package attribute table columns width
    widths = [1.5, 2.0, 1.5, 2.0] # label | value | label | value
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def attribute_table_rows(work_package)
    list = attribute_data_list(work_package)
    0.step(list.length - 1, 2).map do |i|
      build_columns_table_cells(list[i]) +
        build_columns_table_cells(list[i + 1])
    end
  end

  def attribute_data_list(work_package)
    column_entries(%i[id type status])
      .concat(form_configuration_columns(work_package))
      .map { |entry| entry.merge({ value: get_column_value_cell(work_package, entry[:name]) }) }
  end

  def form_configuration_columns(work_package)
    work_package
      .type.attribute_groups
      .filter { |group| group.is_a?(Type::AttributeGroup) }
      .map do |group|
      group.attributes.map do |form_key|
        form_key_to_column_entries(form_key.to_sym, work_package)
      end
    end.flatten
  end

  def form_key_custom_field_to_column_entries(form_key, work_package)
    id = form_key.to_s.sub("custom_field_", "").to_i
    cf = CustomField.find_by(id:)
    return [] if cf.nil? || cf.formattable?

    return [] unless cf.is_for_all? || work_package.project.work_package_custom_field_ids.include?(cf.id)

    [{ label: cf.name || form_key, name: form_key.to_s.sub("custom_field_", "cf_") }]
  end

  def form_key_to_column_entries(form_key, work_package)
    if CustomField.custom_field_attribute? form_key
      return form_key_custom_field_to_column_entries(form_key, work_package)
    end

    if form_key == :date
      column_entries(%i[start_date due_date duration])
    elsif form_key == :bcf_thumbnail
      []
    else
      column_name = ::API::Utilities::PropertyNameConverter.to_ar_name(form_key, context: work_package)
      [column_entry(column_name)]
    end
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
      pdf.make_cell(attribute_data[:label].upcase, styles.wp_attributes_table_label_cell),
      attribute_data[:value]
    ]
  end
end
