class MyHoursController < ApplicationController
  unloadable
  before_filter :find_project
  # before_filter :authorize, only: [:index]
  before_filter :require_admin, only: [:overview]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :issues
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :sort
  include SortHelper
  helper :timelog


  default_search_scope :issues

  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    old_query = session[:query]
    hash = {
        "set_filter" => "1",
        "sort"=>"id:desc",
        "c"=>["status", 'tracker', "subject", "spent_hours"],
        "group_by"=>"#{ params[:date] && params[:date].length > 5 ? 'closed_on_date' : 'closed_on_year' }",
        "t"=>["spent_hours", ""]
    }
    if params[:group_name]
      hash.merge!({
                      "f"=>["status_id", "tracker_id", "closed_on", ""],
                      "op"=>{"status_id"=>"c", "closed_on"=>"><", "tracker_id"=>"!"}
                  })
      d = Date.parse params[:group_name]
      date_begin = d.beginning_of_month.to_date.to_s
      date_end = d.end_of_month.to_date.to_s
      hash.merge!({
                      "v"=>{
                          "closed_on"=>[date_begin, date_end],
                          "tracker_id"=>["1"]
                      }
                  })
      params.merge!(hash)
    else
      hash.merge!({
                     "f"=>["status_id", "tracker_id", ""],
                     "op"=>{"status_id"=>"c", "tracker_id"=>"!"},
                     "v"=>{
                         "tracker_id"=>["1"]
                     }
                 })
      params.merge!(hash)
    end
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
        else
          @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group
      session[:query] = old_query
      respond_to do |format|
        format.html { }
        format.api  {
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues.csv') }
        format.pdf  {
          d = Date.parse params[:group_name]
          send_file_headers! :type => 'application/pdf', :filename => "#{@project.name}_#{d.strftime('%B')}_#{d.strftime('%Y')}.pdf" }
      end
    else
      respond_to do |format|
        format.html {  }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def overview
    old_query = session[:query]
    hash = {
        "set_filter" => "1",
        "sort"=>"id:desc",
        "c"=>["status", 'tracker',  "subject", "spent_hours"],
        "group_by"=>"project",
        "t"=>["spent_hours", ""]
    }
    hash.merge!({
                    "f"=>["status_id", "tracker_id", "closed_on", ""],
                    "op"=>{"status_id"=>"c", "closed_on"=>"><", "tracker_id"=>"!"}
                })
    params[:date] ||= Date.today.strftime('%Y/%m')
    d = Date.parse(params[:date]) rescue Date.today.prev_month
    date_begin = d.beginning_of_month.to_date.to_s
    date_end = d.end_of_month.to_date.to_s
    hash.merge!({
                    "v"=>{
                        "closed_on"=>[date_begin, date_end],
                        "tracker_id"=>["1"]
                    }
                })
    params.merge!(hash)

    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
        else
          @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group
      session[:query] = old_query
      respond_to do |format|
        format.html { render 'my_hours/index'}
        format.api  {
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues.csv') }
        format.pdf  {
          d = Date.parse( params[:group_name] || params[:date]) rescue Date.today
          send_file_headers! :type => 'application/pdf', :filename => "#{@project.name}_#{d.strftime('%B')}_#{d.strftime('%Y')}.pdf" }
      end
    else
      respond_to do |format|
        format.html {  }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def find_project
    @project = Project.find params[:project_id] if params[:project_id]
  rescue
    render_404
  end

end
