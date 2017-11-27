module  RedmineMyHours
  module PdfPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :fetch_row_values, :time_format
      end
    end
      module InstanceMethods
        def fetch_row_values_with_time_format(issue, query, level)
          query.inline_columns.collect do |column|
            s = if column.is_a?(QueryCustomFieldColumn)
                  cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                  show_value(cv, false)
                else
                  value = issue.send(column.name)
                  if column.name == :subject
                    value = "  " * level + value
                  end
                  if column.name == :spent_hours
                    value = value.is_a?(Integer) ? value : value.round(2)
                  end
                  if value.is_a?(Date)
                    format_date(value)
                  elsif value.is_a?(Time)
                    format_time(value)
                  else
                    value
                  end
                end
            s.to_s
          end
        end
      end

  end
end
