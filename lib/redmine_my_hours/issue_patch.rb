require_dependency 'issue'
module  RedmineMyHours
  module IssuePatch
    def self.included(base)
      base.class_eval do
        before_save do
          if self.closed_on
            self.closed_on_date = self.closed_on.strftime('%Y/%m')
          end
        end
      end
    end
  end
end
