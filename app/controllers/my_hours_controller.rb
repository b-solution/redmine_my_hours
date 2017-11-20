class MyHoursController < ApplicationController
  unloadable
  before_filter :find_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :projects
  helper :issues
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :timelog

  def index
    params.merge!({"set_filter" => "1", "sort"=>"id:desc", "f"=>["status_id", ""],
                   "op"=>{"status_id"=>"c"}, "c"=>["status", "subject", "spent_hours"],
                   "group_by"=>"closed_on_date", "t"=>["spent_hours", ""]})
    retrieve_query

    if @query.valid?
      respond_to do |format|
        format.html {
          @issue_count = @query.issue_count
          @issue_pages = Paginator.new @issue_count, per_page_option, params['page']
          @issues = @query.issues(:offset => @issue_pages.offset, :limit => @issue_pages.per_page)
          render :layout => !request.xhr?
        }
      end
    end

  end

  private

  def find_project
    @project = Project.find params[:project_id]
  rescue
    render_404
  end

end
