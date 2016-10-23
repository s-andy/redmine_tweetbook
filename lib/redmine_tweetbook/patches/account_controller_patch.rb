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
            populate_user_data(user, auth_hash)
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

        def populate_user_data(user, auth_hash)
            if auth_hash['provider'] == 'twitter'
                if auth_hash['extra']['raw_info']['lang']
                    # TODO en
                end
                if auth_hash['extra']['raw_info']['time_zone']
                    # TODO
                end
                if auth_hash['extra']['raw_info']['entities']['url']['urls'][0]['expanded_url']
                    # TODO http://www.andriylesyuk.com
                end
                if auth_hash['info']['description']
                    # TODO Developer in @Kayako. Author of Mastering Redmine by @packtpub. Software developer, life analyzer and truth seeker.
                end
                if auth_hash['info']['location']
                    # TODO Ivano-Frankivsk, Ukraine
                end
                if auth_hash['info']['urls']['Twitter']
                    # TODO https://twitter.com/AndriyLesyuk
                end
                if auth_hash['info']['urls']['Website']
                    # TODO http://t.co/Xdn0anT513
                end
                if auth_hash['info']['nickname']
                    # TODO AndriyLesyuk
                end
            elsif auth_hash['provider'] == 'facebook'
                if auth_hash['extra']['raw_info']['gender']
                    # TODO male
                end
                if auth_hash['extra']['raw_info']['locale']
                    # TODO ru_RU
                end
                if auth_hash['extra']['raw_info']['timezone']
                    # TODO 3
                end
                if auth_hash['info']['urls']['Facebook']
                    # TODO https://www.facebook.com/app_scoped_user_id/1313788995299986/
                end
            elsif auth_hash['provider'] == 'github'
                if auth_hash['extra']['raw_info']['company']
                    # TODO Kayako
                end
                if auth_hash['extra']['raw_info']['location']
                    # TODO Ivano-Frankivsk, Ukraine
                end
                if auth_hash['info']['urls']['Blog']
                    # TODO www.andriylesyuk.com
                end
                if auth_hash['info']['urls']['GitHub']
                    # TODO https://github.com/s-andy
                end
            end
        end

      end
    end # end Account Controller patch
  end
end

unless AccountController.included_modules.include?(RedmineTweetbook::Patches::AccountControllerPatch)
  AccountController.send(:include, RedmineTweetbook::Patches::AccountControllerPatch)
end
