class DeleteTweetBooks < ActiveRecord::Migration
  def self.up
    drop_table :tweet_books
  end
end
