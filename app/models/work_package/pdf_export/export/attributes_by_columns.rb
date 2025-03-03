module WorkPackage::PDFExport::Export::AttributesByColumns
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
    attributes_data_by_columns
      .map { |entry| entry.merge({ value: get_column_value_cell(work_package, entry[:name]) }) }
  end

  def attributes_data_by_columns
    column_objects
      .reject { |column| column.name == :subject }
      .map do |column|
      { label: column.caption || "", name: column.name }
    end
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
