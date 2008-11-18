require 'test/unit'
require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'fixtures/article')

class ActsAsPublishableTest < Test::Unit::TestCase

  fixtures :articles

  def setup
    @published_articles = [@undated_article, @published_article, @regular_article]
    @unpublished_articles = [@scheduled_article, @unpublished_article, @fixed_article]
  end

  def test_published
    @published_articles.each { |p| assert p.published?, "Article #{p.id} should not be flagged unpublished, but is: #{p.inspect}" }
    @unpublished_articles.each { |p| assert !p.published?, "Article #{p.id} should not be flagged published, but is: #{p.inspect}" }
  end

  def test_no_dates_should_be_published
    assert Article.find_published(:all).include?(@undated_article)
    assert !Article.find_unpublished(:all).include?(@undated_articlet)
  end
  
  def test_published_posts_should_be_found
    p = Article.find_published(:all)
    @published_articles.each do |post| 
      assert p.include?(post), "Article #{post.id} is not found when using #find_published"
    end
    assert_equal @published_articles.size, p.size
  end
  
  def test_unpublished_posts_should_not_be_found
    p = Article.find_unpublished(:all)
    @unpublished_articles.each do |post| 
      assert p.include?(post), "Article #{post.id} is not found when using #find_unpublished"
    end
    assert_equal @unpublished_articles.size, p.size
  end
  
  def test_publish
    @unpublished_articles.each do |p|
      p.publish
      assert p.published?, "Article #{p.id} should now be published but is not: #{p.inspect}"
      assert !p.reload.published?
      p.publish!
      assert p.reload.published?      
    end
  end
  
  def test_unpublish
    @published_articles.each do |p|
      p.unpublish
      assert !p.published?, "Article #{p.id} should now be unpublished but is not: #{p.inspect}"
      assert p.reload.published?
      p.unpublish!
      assert !p.reload.published?      
    end
  end
  
  def test_date_as_string
    # test getting the values as strings
    assert_equal '2006-05-23 08:00:00', @fixed_article.publish_at_string
    assert_equal '2006-05-24 09:00:00', @fixed_article.unpublish_at_string
    
    # test setting correct values as strings
    new_value = '2006-05-24 08:00:00'
    @fixed_article.publish_at_string = new_value
    assert @fixed_article.save
    assert_equal new_value, @fixed_article.reload.publish_at_string
    assert_equal new_value, @fixed_article.publish_at.to_s(:db)

    new_value = '2006-05-24 10:00:00'
    @fixed_article.unpublish_at_string = new_value
    assert @fixed_article.save
    assert_equal new_value, @fixed_article.reload.unpublish_at_string
    assert_equal new_value, @fixed_article.unpublish_at.to_s(:db)
    
    # test setting incorrect values as strings
    new_value = '2006-32-99 36:201:00'
    @fixed_article.publish_at_string = new_value
    @fixed_article.unpublish_at_string = new_value
    assert !@fixed_article.save
    assert @fixed_article.errors.on(:publish_at)
    assert @fixed_article.errors.on(:unpublish_at)
    assert_equal 'is invalid', @fixed_article.errors.on(:publish_at)
    assert_equal 'is invalid', @fixed_article.errors.on(:unpublish_at)
  end
end