class Site < ActiveRecord::Base
  class UndefinedError < StandardError; end

  has_many :users, :conditions => {:state => 'active'}
  has_many :all_users, :class_name => 'User'
  
  has_many :public_forums, :conditions => "forums.role_id is NULL", :class_name => 'Forum'
  has_many :topics, :through => :public_forums
  has_many :posts,  :through => :public_forums
  
  has_many :all_forums, :class_name => 'Forum'
  
  validates_presence_of   :name
  validates_uniqueness_of :host
  
  attr_readonly :posts_count, :users_count, :topics_count
  
  def host=(value)
    write_attribute :host, value.to_s.downcase
  end
  
  def self.main
    @main ||= find :first, :conditions => {:host => ''}
  end
  
  def self.find_by_host(name)
    return nil if name.nil?
    name.downcase!
    name.strip!
    name.sub! /^www\./, ''
    sites = find :all, :conditions => ['host = ? or host = ?', name, '']
    sites.reject { |s| s.default? }.first || sites.first
  end
  
  def forums(user=nil)
    return public_forums.ordered if !user
    user.forums
  end
  
  def default?
    host.blank?
  end

  def to_s
    name
  end
end
