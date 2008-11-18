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
    # == Requirements
    #
    # This plugin requires Rails 2.1's <tt>named_scope</tt> functions. When using older
    # versions of Rails you can use the 1.0 release of this plugin. Find it at http://github.com/avdgaag/acts_as_publishable/tree/REL-1.0.
    # 
    # == Usage
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
    # You can use two named scopes to find the published or unpublished objects.
    # Use them like you use your standard <tt>#find</tt>:
    #   
    #   Post.find(:all).size              # => 15
    #   Post.published.size               # => 10
    #   Post.unpublished.size             # => 5
    # 
    # Read more about named scope in the Rails documentation.
    # 
    # There is also the <tt>#published_only</tt> scope, that accepts a boolean
    # flag indicating whether the scope should be applied or not. By default,
    # it will apply it--but you can disable it if you want to (say, when a
    # user is an administrator allowed to say all).
    #
    # Example:
    #
    #   post.published_only(current_user.admin?)
    #
    # Here, admin users get all posts, normal users get only published posts.
    #
    # == Setting the dates as strings
    #
    # You can use the <tt>publish_at</tt> and <tt>unpublish_at</tt> attributes
    # like any other. Do note that this plugin comes with two special virtual
    # attributes that allow you to set the dates as strings, that is: with 
    # text fields rather than select boxes:
    #
    #   <%= f.text_field :publish_at_string %>
    #
    # <tt>publish_at_string</tt> and <tt>unpublish_at_string</tt> will
    # return their values formatted as strings, while <tt>publish_at_string=</tt>
    # <tt>publish_at_string=</tt> will try to parse the strings passed to them.
    # When the strings cannot be parsed the model will be invalid.
    #
    # == Credits
    #
    # acts_as_pubishable was written by Arjan van der Gaag (http://github.com/avdgaag) with contributions
    # from Ismael Celis (http://github.com/ismasan).
    #
    # Version:: 1.1
    # Author:: Arjan van der Gaag
    # URL:: http://github.com/avdgaag/acts_as_publishable
    # License:: MIT
    #
    # == History
    #
    # === 1.1: 
    # 
    # * refactor to use <tt>named_scope</tt>. Rails 2.1 or greater now required. By Ismael Celis.
    # * Updated documentation
    # * Use a custom validation method rather than <tt>#validate</tt>
    #
    # === 1.0:
    # 
    # * first release.
    module Publishable
    
      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
    
      module ClassMethods
        # == Configuration options
        #
        # Right now this plugin has only one configuration option. Models with no publication dates
        # are by default published, not unpublished. If you want to hide your model when it has no
        # explicit publication date set, you can turn off this behaviour with the
        # +publish_by_default+ (defaults to <tt>true</tt>) option like so:
        #
        #   class Post < ActiveRecord::Base
        #     acts_as_publishable :publish_by_default => false
        #   end
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
        def acts_as_publishable(options = { :publish_by_default => true })
          # don't allow multiple calls
          return if self.included_modules.include?(Agw::Acts::Publishable::InstanceMethods)
          send :include, Agw::Acts::Publishable::InstanceMethods
          
          named_scope :published, :conditions => published_conditions
          named_scope :unpublished, :conditions => unpublished_conditions
          
          named_scope :published_only, lambda { |*args|
            bool = (args.first.nil? ? true : (args.first)) # nil = true by default
            {:conditions => (bool ? published_conditions : unpublished_conditions)}
          }
          
          after_create :set_default_publication_date if options[:publish_by_default]
          validate :sensible_publication_dates_as_string
        end
        
        # Special finder method for finding all objects that are published.
        # Use the same way as #find
        #
        # DEPRECATED: use Thing.published.find(*args) instead
        def find_published(*args)
          published.find(*args)
        end
        
        # Special finder method for finding all objects that are not published.
        # Use the same way as #find
        #
        # DEPRECATED: use Thing.unpublished.find(*args) instead
        def find_unpublished(*args)
          unpublished.find(*args)
        end
        
        protected

          # returns a string for use in SQL to filter the query to unpublished results only
          # Meant for internal use only.
          def unpublished_conditions
            "(#{table_name}.publish_at IS NOT NULL AND #{table_name}.publish_at > '#{Time.now.to_s(:db)}') OR (#{table_name}.unpublish_at IS NOT NULL AND #{table_name}.unpublish_at < '#{Time.now.to_s(:db)}')"
          end
        
          # return a string for use in SQL to filter the query to published results only
          # Meant for internal use only.
          def published_conditions
            "(#{table_name}.publish_at IS NULL OR #{table_name}.publish_at <= '#{Time.now.to_s(:db)}') AND (#{table_name}.unpublish_at IS NULL OR #{table_name}.unpublish_at > '#{Time.now.to_s(:db)}')"
          end
      end
      
      module InstanceMethods
        
        # virtual attribute that returns the publication date as string
        # so it can be used in text fields rather than with Rails'
        # default and unfriendly select boxes.
        def publish_at_string
          publish_at.strftime('%Y-%m-%d %H:%M:%S') unless publish_at.nil?
        end

        # virtual attribute that returns the unpublication date as string
        # so it can be used in text fields rather than with Rails'
        # default and unfriendly select boxes.
        def unpublish_at_string
          unpublish_at.strftime('%Y-%m-%d %H:%M:%S') unless unpublish_at.nil?
        end
        
        # virtual attribute setter that takes the publication date as string
        # so it can be used in text fields rather than with Rails'
        # default and unfriendly select boxes.
        #
        # Any errors are caught and the flag that is raised will be handled in the custom
        # validation method.
        #--
        # TODO: this method may need some more sanity-checking since the ArgumenError may not always be raised when expected.
        def publish_at_string=(t)
          self.publish_at = t.blank? ? nil : Time.parse(t)
        rescue ArgumentError
          @publish_at_is_invalid = true
        end
        
        # virtual attribute that takes the unpublication date as string
        # so it can be used in text fields rather than with Rails'
        # default and unfriendly select boxes.
        #
        # Any errors are caught and the flag that is raised will be handled in the custom
        # validation method.
        #--
        # TODO: this method may need some more sanity-checking since the ArgumenError may not always be raised when expected.
        def unpublish_at_string=(t)
          self.unpublish_at = t.blank? ? nil : Time.parse(t)
        rescue ArgumentError
          @unpublish_at_is_invalid = true
        end
        
        # ActiveRecrod callback fired on +after_create+ to make 
        # sure a new object always gets a publication date; if 
        # none is supplied it defaults to the creation date.
        def set_default_publication_date
          update_attribute(:publish_at, created_at) if publish_at.nil?
        end
        
      private
        
        # Custom validation that handles badly formatted date/time input
        # given via <tt>publish_at_string=</tt> and <tt>unpublish_at_string=</tt>.
        #--
        # TODO: change the error message to the Rails default 'invalid' error message.
        def sensible_publication_dates_as_string
          errors.add(:publish_at, 'is invalid')   if @publish_at_is_invalid
          errors.add(:unpublish_at, 'is invalid') if @unpublish_at_is_invalid
        end
        
      public
        
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