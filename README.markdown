NOTE: This project is outdated. Use is not recommended. It is kept online as a reminder of the code I wrote several years ago, making the stuff I do now look good.

# acts\_as\_publishable 1.1

This plugin lets you add basic time-based publishing-behaviour to your models by specifying a publication range with to date attributes.

## Usage

To use simply call the plugin in your model:

    class Post < ActiveRecord::Base
      acts_as_publishable
    end

This includes two special finder methods for finding published and unpublished models, and adds some basic instance methods for working with individual objects--most notably the `published?`-flag.

## Testing

You can check if the plugin installed correctly by testing it yourself (in the plugin dir.):

    rake test

## More information

Find more information in the inline documentation or at this plugin's homepage at [github.com/avdgaag/acts_as_publishable][1].

Copyright (c) 2007 Arjan van der Gaag, released under the MIT license

[1]: http://github.com/avdgaag/acts_as_publishable
