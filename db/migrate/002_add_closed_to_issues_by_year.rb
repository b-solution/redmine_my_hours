class AddClosedToIssuesByYear < ActiveRecord::Migration
  def change
    add_column :issues, :closed_on_year, :string, default: ''

    Issue.where.not(closed_on: nil).update_all('closed_on_year = concat(YEAR(closed_on))')
  end
end
