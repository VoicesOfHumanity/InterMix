class ApiController < ApplicationController
    #-- This is mainly a back end for apps like Facebook, Google, etc.

    append_before_action :check_api_code

    @api_code = 'Xe6tsdfasf'

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

    protected

    def check_api_code
        if params[:x] != @api_code
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
        info = {
            id: participant.id,
            email: participant.email,
            name: participant.name,
            user_img_link: user_img_link,
        }
        return info
    end 

    end

end
