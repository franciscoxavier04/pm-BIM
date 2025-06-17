module Exports
  module Formatters
    class CustomFieldPdf < CustomField
      def self.apply?(attribute, export_format)
        export_format == :pdf && attribute.start_with?("cf_")
      end

      ##
      # Print the value meant for export.
      #
      # - For boolean values, use the Yes/No formatting for the PDF
      #   treat nil as false
      # - For long text values, output the plain value
      def format_for_export(object, custom_field)
        case custom_field.field_format
        when "bool"
          value = object.typed_custom_value_for(custom_field)
          value ? I18n.t(:general_text_Yes) : I18n.t(:general_text_No)
        when "text"
          object.typed_custom_value_for(custom_field)
        when "hierarchy"
          format_hierarchy_for_export(object, custom_field)
        else
          object.formatted_custom_value_for(custom_field)
        end
      end

      def format_hierarchy_for_export(object, custom_field)
        cvs = object.custom_value_for(custom_field)
        case cvs
        when Array
          cvs.map { |item| format_hierarchy_item_for_export(item) }
        when CustomValue
          format_hierarchy_item_for_export(cvs)
        else
          cvs
        end
      end

      def format_hierarchy_item_for_export(item_value)
        item = ::CustomField::Hierarchy::Item.find_by(id: item_value.to_s)
        return "#{item_value} #{I18n.t(:label_not_found)}" if item.nil?

        nodes = hierarchy_item_service.get_branch(item:).value!
        nodes
          .reject(&:root?)
          .map do |branch_item|
          branch_item.short.present? ? "#{branch_item.label} (#{branch_item.short})" : branch_item.label
        end.join(" / ")
      end

      def hierarchy_item_service
        ::CustomFields::Hierarchy::HierarchicalItemService.new
      end
    end
  end
end
