class User < ActiveRecord::Base
  concerned_with :states, :activation, :posting, :validation
  formats_attributes :bio
  
  User.inheritance_column = 'ruby_type'
  before_save :add_user_role
  has_and_belongs_to_many :roles
  
  def admin?
    has_role?('admin')
  end
  alias_method :admin, :admin?
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    (@_list.include?(role_in_question.to_s) )
  end
  
  acts_as_authentic do |c|
     c.transition_from_restful_authentication = true
     #AuthLogic defaults
     #c.validate_email_field = true
     #c.validates_length_of_email_field_options = {:within => 6..100} 
     #c.validates_format_of_email_field_options = {:with => email_regex, :message => I18n.t(‘error_messages.email_invalid’, :default => “should look like an email address.”)}
     #c.validate_password_field = true
     #c.validates_length_of_password_field_options = {:minimum => 4, :if => :require_password?} 
     #for more defaults check the AuthLogic documentation
  end

  belongs_to :site, :counter_cache => true
  validates_presence_of :site_id
  
  has_many :posts, :order => "#{Post.table_name}.created_at desc"
  has_many :topics, :order => "#{Topic.table_name}.created_at desc"
  
  has_many :moderatorships, :dependent => :delete_all
  has_many :mod_forums, :through => :moderatorships, :source => :forum do
    def moderatable
      find :all, :select => "#{Forum.table_name}.*, #{Moderatorship.table_name}.id as moderatorship_id"
    end
  end
  
  has_many :monitorships, :dependent => :delete_all
  has_many :monitored_topics, :through => :monitorships, :source => :topic, :conditions => {"#{Monitorship.table_name}.active" => true}
  
  has_permalink :login, :scope => :site_id
  
  attr_readonly :posts_count, :last_seen_at

  named_scope :named_like, lambda {|name|
    { :conditions => ["users.display_name like ? or users.login like ?", 
                        "#{name}%", "#{name}%"] }}

  def self.prefetch_from(records)
    find(:all, :select => 'distinct *', :conditions => ['id in (?)', records.collect(&:user_id).uniq])
  end
  
  def self.index_from(records)
    prefetch_from(records).index_by(&:id)
  end

  def available_forums
    @available_forums ||= forums - mod_forums
  end

  def moderator_of?(forum)
    !!(admin? || Moderatorship.exists?(:user_id => id, :forum_id => forum.id))
  end
  
  def forums
    return self.site.all_forums if admin?
    self.site.all_forums.find(:conditions => ["role_id is NULL OR role_id IN ?", self.role_ids])
  end
  
  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.deliver_password_reset_instructions(self)
  end

  def display_name
    n = read_attribute(:display_name)
    n.blank? ? login : n
  end

  alias_method :to_s, :display_name
  
  # this is used to keep track of the last time a user has been seen (reading a topic)
  # it is used to know when topics are new or old and which should have the green
  # activity light next to them
  #
  # we cheat by not calling it all the time, but rather only when a user views a topic
  # which means it isn't truly "last seen at" but it does serve it's intended purpose
  #
  # This is now also used to show which users are online... not at accurate as the
  # session based approach, but less code and less overhead.
  def seen!
    now = Time.now.utc
    self.class.update_all ['last_seen_at = ?', now], ['id = ?', id]
    write_attribute :last_seen_at, now
  end
  
  def to_param
    id.to_s # permalink || login
  end

  def openid_url=(value)
    write_attribute :openid_url, value.blank? ? nil : OpenIdAuthentication.normalize_identifier(value)
  end

  def using_openid
    self.openid_url.blank? ? false : true
  end
  
  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :email << :login_key << :login_key_expires_at << :password_hash << :openid_url << :activated << :admin
    super
  end
  
  private 
  def add_user_role
    user_role = Role.find_by_name("user")
    self.roles << user_role if user_role and self.roles.empty?
  end

end
