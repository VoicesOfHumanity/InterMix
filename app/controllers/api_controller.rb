class ApiController < ApplicationController
    #-- This is mainly a back end for apps like Facebook, Google, etc.

    logger                                         = Logger.new(STDOUT)
    logger.level                                   = Logger::INFO

    append_before_action :check_api_code

    include ItemLib

    def verify_email
        email = params[:email].to_s
        participant = Participant.find_by(email: params[:email])
        if participant
            Rails.logger.info("api verify_email: ok")
            render json: {
                status: 'success',
                user: user_info(participant)
            }
        else
            logger.info("api verify_email: not found")
            render json: {
                status: 'error',
                message: 'User not found'
            }
        end
    end

    def login
        email = params[:email].to_s
        password = params[:pass].to_s
        participant = Participant.find_by(email: params[:email])
        Rails.logger.info("api login: user found") if participant
        if participant and participant.valid_password?(password)
            Rails.logger.info("api login: password ok")
            render json: {
                status: 'success',
                user: user_info(participant)
            }
        else
            Rails.logger.info("api login: password not ok")
            if participant
                xmess = "user found. password not right"
            else
                xmess = "user not found"
            end
            render json: {
            status: 'error',
            message: 'Not valid: ' + xmess
            }
        end
    end

    def logout

    end

    def register

    end

    def get_user
        id = params[:id].to_i
        Rails.logger.info("api#get_user: id: #{id}")
        participant = Participant.find_by_id(id)
        if participant
            render json: {
                status: 'success',
                user: user_info(participant)
            }
        else
            render json: {
                status: 'error',
                message: 'User not found'
            }
        end
    end

    def update_user
        data = JSON.parse(request.raw_post)
        id = data['user_id'].to_i
        Rails.logger.info("api#update_user: id: #{id}")
        p = Participant.find_by_id(id)
        if p
            @participant = p
            @oldparticipant = p.dup
            if data.has_key?('country_code')
                p.country_code = data['country_code']
            elsif data.has_key?('country_name')
                country = Geocountry.where(name: data['country_name']).first
                if country
                    p.country_code = country.iso
                    p.country_name = country.name
                end
            end
            if data.has_key?('admin1uniq')
                p.admin1uniq = data['admin1uniq']
            end
            if data.has_key?('city')
                p.city = data['city']
                p.city_uniq = data['admin1uniq'] + '_' + data['city']
            end
            if data.has_key?('country_code2')
                p.country_code = data['country_code2']
            end
            if data.has_key?('generation_id')
                p.update_generation(data['generation_id'])
            end
            if data.has_key?('gender_id')
                p.update_gender(data['gender_id'])
            end
            p.save
            geoupdate
            render json: {
                status: 'success: '+data.inspect
            }
        else
            render json: {
                status: 'error',
                message: "User #{id} not found"
            }
        end
    end

    def thumbrate
        #-- rate an item with up or down thumbs
        @from = params[:from] || 'api'
        item_id = params[:item_id].to_i
        vote = params[:vote].to_i
        user_id = params[:user_id].to_i
        Rails.logger.level = 1
        Rails.logger.info("api#thumbrate item:#{item_id} user:#{user_id} vote:#{vote}")

        participant = Participant.find_by_id(user_id)
        sign_in participant
    
        item = Item.includes(:dialog,:group).find_by_id(item_id)
    
        #-- Check if they're allowed to rate it
        if not item.voting_ok(current_participant.id)
            render json: {
                status: 'error',
                message: "Not allowed to rate"
            }
            return
        end
        
        rateitem(item, vote)
        
        render json: {
            status: 'success'
        }
      end

    protected

    def check_api_code
        Rails.logger.level = 1
        Rails.logger.info("api#check_api_code")
        @api_code = 'Xe6tsdfasf'
        if params[:x] != @api_code
            Rails.logger.info("api#check_api_code: not ok")
            render json: {
                status: 'error',
                message: 'Access denied'
            }
        end
    end

    def user_info(participant)
        if participant.picture.exists?
            user_img_link = participant.picture.url(:thumb)
        else
            user_img_link = "/images/default_user_icon-50x50.png"
        end 
        user_img_link = "https://#{BASEDOMAIN}#{user_img_link}"

        info = {
            id: participant.id,
            email: participant.email,
            name: participant.name,
            user_img_link: user_img_link,
            country_code: participant.country_code,
            country_name: participant.country_name,
            country_code2: participant.country_code2,
            country_name2: participant.show_country2,
            admin1uniq: participant.admin1uniq,
            city_uniq: participant.city_uniq,
            city: participant.city,
            gender_id: participant.gender_id,
            gender: participant.gender,
            generation_id: participant.generation_id,
            generation: participant.generation,
            auth_token: participant.authentication_token
        }
        return info
    end 

end
