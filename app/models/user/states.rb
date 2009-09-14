class User
  acts_as_state_machine :initial => :passive
  state :passive
  state :pending, :after => :do_activation
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete
  
  event :register do
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end
  
  event :activate do
    transitions :from => :pending, :to => :active 
  end
  
  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended, :guard => :remove_moderatorships
  end
  
  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end
  
  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.perishable_token.blank? }
    transitions :from => :suspended, :to => :passive
  end
  
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login}
    u && u.authenticated?(password) ? u : nil
  end

  def do_activation
    reset_perishable_token!
    UserMailer.deliver_signup_notification(self) unless using_openid
  end

protected
  def do_delete
    self.deleted_at = Time.now.utc
  end

  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = nil
  end
  
  def remove_moderatorships
    moderatorships.delete_all
  end
end
