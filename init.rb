Redmine::Plugin.register :redmine_my_hours do
  name 'Redmine My Hours plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  project_module :my_hours do
    permission :view_my_hours, :my_hours => [:index]
  end

  ActiveRecord::Base.default_timezone = :utc

  menu :project_menu, :my_hours, {:controller => 'my_hours', :action => 'index' },
       caption: :my_hours,
       :if => Proc.new {
         User.current.allowed_to_globally?(:my_hours, {})
       },
       :after => :activity, param: :project_id

  Rails.application.config.to_prepare do
    Issue.send(:include, RedmineMyHours::IssuePatch)
    IssueQuery.send(:include, RedmineMyHours::IssueQueryPatch)
  end
end
