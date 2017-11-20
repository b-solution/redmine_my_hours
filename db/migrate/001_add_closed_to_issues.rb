class AddClosedToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :closed_on_date, :string, default: ''

    Issue.where.not(closed_on: nil).update_all('closed_on_date = concat(YEAR(closed_on),"/", MONTH(closed_on) )')
  end
end
