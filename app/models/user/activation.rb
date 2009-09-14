class User
  # include Authentication
  # include Authentication::ByPassword
  # include Authentication::ByCookieToken

  after_create :set_first_user_as_activated
  def set_first_user_as_activated
    register! && activate! if site.nil? or site.users.count <= 1
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def active?
    if passive?
      self[:state] = 'pending'
      activate!
    end
    
    self.state == 'active'
  end
end
