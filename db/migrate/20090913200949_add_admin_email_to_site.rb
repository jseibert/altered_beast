class AddAdminEmailToSite < ActiveRecord::Migration
  def self.up
    add_column :sites, :admin_email, :string
  end

  def self.down
    remove_column :sites, :admin_email
  end
end
