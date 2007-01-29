class Article < ActiveRecord::Base
  acts_as_publishable
  
  def slug
    'hello world'
  end
end