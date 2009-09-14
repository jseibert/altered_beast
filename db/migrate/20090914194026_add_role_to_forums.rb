class AddRoleToForums < ActiveRecord::Migration
  def self.up
    add_column :forums, :role_id, :integer
  end

  def self.down
    remove_column :forums, :role_id
  end
end
