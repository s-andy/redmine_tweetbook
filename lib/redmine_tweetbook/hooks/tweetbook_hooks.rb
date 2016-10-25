module RedmineTweetbook
  module Hooks
    class TweetbookHooks < Redmine::Hook::ViewListener      
      render_on :view_account_login_top, :partial => 'shared/tweetbook'
    end
  end
end
