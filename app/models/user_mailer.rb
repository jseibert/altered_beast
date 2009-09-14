class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = activate_url(user.perishable_token, :host => user.site.host)
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = root_url(:host => user.site.host)
  end
  
  def password_reset_instructions(user)
    setup_email(user)
    @subject    += 'Reset your password'
    @body[:url]  = edit_password_reset_url(user.perishable_token, :host => user.site.host)
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "#{user.site.admin_email}"
      @subject     = "[#{user.site.name}] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
