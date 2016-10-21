module RedmineTweetbook
  module Patches
    module AccountControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods

        def tweetbook_authenticate
          auth_hash = request.env['omniauth.auth']

          unless auth_hash['info']['name'] && auth_hash['info']['email']
            flash[:error] = l(:notice_account_missing_data)
            redirect_to(home_url)
            return
          end

          user = User.find_or_initialize_by(:mail => auth_hash['info']['email'])
          if user.new_record?
            # Self-registration off
            redirect_to(home_url) && return unless Setting.self_registration?

            # Create on the fly
            user.login = auth_hash['info']['email']
            user.mail  = auth_hash['info']['email']
            user.firstname, user.lastname = auth_hash['info']['name'].split(' ')
            user.random_password
            user.register

            case Setting.self_registration
            when '1'
              register_by_email_activation(user) do
                onthefly_creation_failed(user)
              end
            when '3'
              register_automatically(user) do
                onthefly_creation_failed(user)
              end
            else
              register_manually_by_administrator(user) do
                onthefly_creation_failed(user)
              end
            end
          else
            # Existing record
            if user.active?
              successful_authentication(user)
            else
              account_pending(user)
            end
          end
        rescue AuthSourceException => e
          logger.error "An error occured when authenticating #{e.message}"
          render_error :message => e.message
        end

      end
    end # end Account Controller patch
  end
end

unless AccountController.included_modules.include?(RedmineTweetbook::Patches::AccountControllerPatch)
  AccountController.send(:include, RedmineTweetbook::Patches::AccountControllerPatch)
end
