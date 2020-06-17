require_dependency 'issue'
module  RedmineMyHours
  module IssuePatch
    def self.included(base)
      base.class_eval do
        before_save do
          if self.closed_on
            self.closed_on_date = self.closed_on.strftime('%Y/%m')
            self.closed_on_year = self.closed_on.strftime('%Y')
          end
        end
      end
    end
  end
end
