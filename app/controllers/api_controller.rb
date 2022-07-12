class ApiController < ApplicationController
    #-- This is mainly a back end for apps like Facebook, Google, etc.

    append_before_action :check_api_code

    def verify_email
        email = params[:email].to_s
        participant = Participant.find_by(email: params[:email])
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

    def login
        email = params[:email].to_s
        password = params[:pass].to_s
        participant = Participant.find_by(email: params[:email])
        if participant and participant.valid_password?(password)
            render json: {
                status: 'success',
                user: user_info(participant)
            }
        else
            render json: {
            status: 'error',
            message: 'Not valid'
            }
        end
    end

    def logout

    end

    def register

    end

    def get_user
        id = params[:id].to_i
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
        id = params[:user_id].to_i
        p = Participant.find_by_id(id)
        if params
            if params[:country_code]
                p.country_code = params[:country_code]
            end
            if params[:generation_id]
                p.update_generation(params[:generation_id])
            end
            if params[:gender_id]
                p.update_gender(params[:gender_id])
            end
            p.save
            render json: {
                status: 'success'
            }
        else
            render json: {
                status: 'error',
                message: 'User not found'
            }
        end
    end

    protected

    def check_api_code
        @api_code = 'Xe6tsdfasf'
        if params[:x] != @api_code
            render json: {
                status: 'error',
                message: 'Access denied'+"x: #{params[:x]} != @api_code: #{@api_code}"
            }
        end
    end

    def user_info(participant)
        if participant.picture.exists?
            user_img_link = participant.picture.url(:thumb)
        else
            user_img_link = "/images/default_user_icon-50x50.png"
        end 
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
            generation: participant.generation
        }
        return info
    end 

end
