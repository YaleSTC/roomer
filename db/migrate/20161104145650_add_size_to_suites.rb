class AddSizeToSuites < ActiveRecord::Migration[5.0]
  def change
    add_column :suites, :size, :integer, null: false, default: 0
  end
end
