ActiveRecord::Schema.define(:version => 0) do
  create_table :articles, :force => true do |t|
    t.column :title, :string
    t.column :publish_at, :datetime
    t.column :unpublish_at, :datetime
  end
end
