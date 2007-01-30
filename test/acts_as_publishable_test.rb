require 'test/unit'
require File.join(File.dirname(__FILE__), 'abstract_unit')
require File.join(File.dirname(__FILE__), 'fixtures/article')

class ActsAsPublishableTest < Test::Unit::TestCase

  fixtures :articles

  def setup
    @published_articles = [@undated_article, @published_article, @regular_article]
    @unpublished_articles = [@scheduled_article, @unpublished_article]
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
  
  def test_published_only
    @set1 = Article.find_published :all
    Article.published_only do
      @set2 = Article.find :all
    end
    assert_equal @set1, @set2
    
    @set1 = Article.find_unpublished :all
    Article.unpublished_only do
      @set2 = Article.find :all
    end
    assert_equal @set1, @set2
  end
end
