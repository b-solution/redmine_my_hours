module  RedmineMyHours
  module IssueQueryPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :available_columns, :my_hours
      end
    end
  end
  module ClassMethods
  end

  module InstanceMethods
    def available_columns_with_my_hours
      if @available_columns.blank?
        @available_columns = available_columns_without_my_hours
        @available_columns << QueryColumn.new(:closed_on_date, :sortable => "(#{Issue.table_name}.closed_on_date)", :default_order => 'desc', :groupable => true)
      else
        available_columns_without_my_hours
      end
      @available_columns
    end

  end
  module QueryInstanceMethods
    def value_object_with_qr_code(object)
      if name == :qr_code
        "<div class='issue_qrcode' title='#{issue_url(object, host: Setting.host_name, protocol: Setting.protocol) }'></div>".html_safe
      else
        value_object_without_qr_code(object)
      end
    end
  end
end