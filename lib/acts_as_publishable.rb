#  Copyright (c) 2007 Arjan van der Gaag
#  
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#  
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Agw #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you want to show or hide your object based on date/time settings. This act lets you
    # specify two dates two form a range in which the model is publicly available; it is unavailable outside it.
    # 
    # Usage
    # 
    # You can add this behaviour to your model like so:
    # 
    #   class Post < ActiveRecord::Base
    #     acts_as_publishable
    #   end
    # 
    # Then you can use it as follows:
    # 
    #   post = Post.create(:title => 'Hello world')
    #   post.published? # => true
    #   
    #   post.publish!
    #   post.published? # => true
    #   
    #   post.unpublish!
    #   post.published? # => false
    #   
    # You can use two special finder methods to find the published or unpublished objects.
    # Use them like you use your standard <tt>#find</tt>:
    #   
    #   Post.find(:all).size              # => 15
    #   Post.find_published(:all).size    # => 10
    #   Post.find_unpublished(:all).size  # => 5
    # 
    module Publishable
    
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
    
      module ClassMethods
        # == Configuration options
        #
        # Right now this plugin has no configuration options. Do note that models with no publication dates
        # are by default published, not unpublished. So, if you want to hide your model you have to explicitly
        # set these dates.
        #
        # == Database Schema
        #
        # The model that you're publishing needs to have two special date attributes:
        # 
        # * publish_at
        # * unpublish_at
        # 
        # These attributes have no further requirements or required validations; they
        # just need to be <tt>datetime</tt>-columns.
        # 
        # You can use a migration like this to add these columns to your model:
        #
        #   class AddPublicationDatesToPosts < ActiveRecord::Migration
        #     def self.up
        #       add_column :posts, :publish_at, :datetime
        #       add_column :posts, :unpublish_at, :datetime
        #     end
        #   
        #     def self.down
        #       remove_column :posts, :publish_at
        #       remove_column :posts, :unpublish_at
        #     end
        #   end
        # 
        def acts_as_publishable()
          # don't allow multiple calls
          return if self.included_modules.include?(Agw::Acts::Publishable::InstanceMethods)
          send :include, Agw::Acts::Publishable::InstanceMethods
        end
        
        # Special finder method for finding all objects that are published.
        # Use the same way as #find
        def find_published(*args)
          t = Time.now.to_s(:db)
          c = "(publish_at IS NULL OR publish_at <= '#{t}') AND (unpublish_at IS NULL OR unpublish_at > '#{t}')"
          with_scope :find => { :conditions => c} do
            find(*args)
          end
        end
        
        # Special finder method for finding all objects that are not published.
        # Use the same way as #find
        def find_unpublished(*args)
          t = Time.now.to_s(:db)
          c = "(publish_at IS NOT NULL AND publish_at > '#{t}') OR (unpublish_at IS NOT NULL AND unpublish_at < '#{t}')"
          with_scope :find => { :conditions => c } do
            find(*args)
          end
        end
      end
      
      module InstanceMethods
        
        # Return whether the current object is published or not
        def published?
          (publish_at.nil? || (publish_at <=> Time.now) <= 0) && (unpublish_at.nil? || (unpublish_at <=> Time.now) >= 0)
        end
        
        # Indefinitely publish the current object right now
        def publish
          return if published?
          self.publish_at = Time.now
          self.unpublish_at = nil
        end
        
        # Same as publish, but immediatly saves the object.
        # Raises an error when saving fails.
        def publish!
          publish
          save!
        end
        
        # Immediatly unpublish the current object
        def unpublish
          return unless published?
          self.unpublish_at = 1.minute.ago
        end
        
        # Same as unpublish, but immediatly saves the object.
        # Raises an error when saving files.
        def unpublish!
          unpublish
          save!
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Agw::Acts::Publishable