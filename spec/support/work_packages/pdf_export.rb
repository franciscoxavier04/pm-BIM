# frozen_string_literal: true

require "spec_helper"
require "pdf/inspector"

module PDFExportSpecUtils
  def column_title(column_name)
    label_title(column_name)
  end

  def label_title(column_name)
    if column_name.start_with?("cf_")
      id = column_name.delete_prefix("cf_").to_i
      return ::CustomField.find_by(id:).name
    end
    WorkPackage.human_attribute_name(column_name)
  end
end
