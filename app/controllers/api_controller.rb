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

    def user_from_facebook
        # A facebook user has logged in, and we want to see if they are already an intermix user
        # If not, create them
        # Return the user info
        Rails.logger.info("api#user_from_facebook")
        data = JSON.parse(request.raw_post)
        Rails.logger.info("api#user_from_facebook: data: #{data.inspect}")
        fb_uid = data['facebook_id']
        email = data['email']
        name = data['name']
        explanation = ''

        participant = Participant.where(fb_uid: fb_uid, email: email).first
        if participant
            Rails.logger.info("api#user_from_facebook: found participant by fb_uid and email: #{participant.id}")
            explanation = 'existing user found by fb_uid and email'
        end
        if not participant
            participant = Participant.find_by_fb_uid(fb_uid)
            if participant
                Rails.logger.info("api#user_from_facebook: found participant by fb_uid: #{participant.id}")
                explanation = 'existing user found by fb_uid'
            end
        end
        if not participant
            participant = Participant.find_by_email(email)
            if participant
                Rails.logger.info("api#user_from_facebook: found participant by email: #{participant.id}")
                explanation = 'existing user found by email'
                if not participant.fb_uid or participant.fb_uid == ''
                    participant.fb_uid = fb_uid
                    participant.save
                end
            end
        end
        if not participant
            Rails.logger.info("api#user_from_facebook: creating participant")
            explanation = 'new user created'
            participant = Participant.new
            narr = @name.split(' ')
            last_name = narr[narr.length-1]
            first_name = ''
            first_name = narr[0,narr.length-1].join(' ') if narr.length > 1
            participant.first_name = first_name
            participant.last_name = last_name
            participant.email = email
            participant.fb_uid = fb_uid
            participant.save
        end
        if participant.fb_uid.to_i >0 and not participant.picture.exists?
            #-- Use their facebook photo, if they don't already have one.
            url = "https://graph.facebook.com/#{participant.fb_uid}/picture?type=large"
            participant.picture = URI.parse(url).open
            participant.save
        end
        render json: {
            status: 'success',
            message: explanation,
            user: user_info(participant)
        }
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

    def update_user_field
        data = JSON.parse(request.raw_post)
        id = data['user_id'].to_i
        Rails.logger.info("api#update_user_field: id: #{id}")
        field_name = data['field_name']
        field_value = data['field_value']
        p = Participant.find_by_id(id)
        if p
            @participant = p
            @oldparticipant = p.dup
            if field_name == 'countryCode'
                p.country_code = field_value
                if p.country_code != @oldparticipant.country_code
                    p.admin1uniq = ''
                    p.city = ''
                    p.city_uniq = ''
                end
            elsif field_name == 'admin1uniq'
                p.admin1uniq = field_value
                if p.admin1uniq != @oldparticipant.admin1uniq
                    p.city = ''
                    p.city_uniq = ''
                end
            elsif field_name == 'city'
                p.city = field_value
                p.city_uniq = p.admin1uniq + '_' + p.city
            elsif field_name == 'generationId'
                p.update_generation(field_value)
            elsif field_name == 'genderId'
                p.update_gender(field_value)
            elsif field_name == 'religionIDs'
                religion_ids = field_value
                has_indigenous = false
                for rel in Religion.all
                    if religion_ids.include?(rel.id)
                        #logger.info("api#update_user_field: rel: #{rel.id} #{rel.name} try to add")
                        if not p.religions.include?(rel)
                            p.religions << rel
                        end
                        p.tag_list.add(rel.shortname)
                        if rel.name == 'Indigenous'
                            has_indigenous = true
                        end
                    else
                        #logger.info("api#update_user_field: rel: #{rel.id} #{rel.name} try to delete")
                        p.religions.delete(rel)
                        p.tag_list.remove(rel.shortname)
                    end
                end
                if has_indigenous
                    # If they have the indigenous religion, add them to nations too, if they don't already have two nations
                    if p.country_code2.to_s == '' and p.country_code2 != '_I' and p.country_code != '_I'
                        p.country_code2 = '_I'
                    end
                end
            elsif field_name == 'communityIDs'
                community_ids = field_value
                major_communities = Community.where(major: true).order(:fullname)
                for com in major_communities
                    if community_ids.include?(com.id)
                        if not p.communities.include?(com)
                            p.communities << com
                        end
                        p.tag_list.add(com.tagname)
                    else
                        p.communities.delete(com)
                        p.tag_list.remove(com.tagname)
                    end
                end
            end
            p.save

            geoupdate

            render json: {
                status: 'success'
            }
        else
            render json: {
                status: 'error',
                message: "User #{id} not found"
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
                p.country_code2 = data['country_code2']
            end
            if data.has_key?('generation_id')
                p.update_generation(data['generation_id'])
            end
            if data.has_key?('gender_id')
                p.update_gender(data['gender_id'])
            end
            p.save

            has_indigenous = false
            if data.has_key?('religion_ids')
                religion_ids = data['religion_ids']
                for rel in Religion.all
                    if religion_ids.include?(rel.id)
                        logger.info("api#update_user: rel: #{rel.id} #{rel.name} try to add")
                        if not p.religions.include?(rel)
                            p.religions << rel
                        end
                        p.tag_list.add(rel.shortname)
                        if rel.name == 'Indigenous'
                            has_indigenous = true
                        end
                    else
                        logger.info("api#update_user: rel: #{rel.id} #{rel.name} try to delete")
                        p.religions.delete(rel)
                        p.tag_list.remove(rel.shortname)
                    end
                end
            end
            if has_indigenous
                # If they have the indigenous religion, add them to nations too, if they don't already have two nations
                if p.country_code2.to_s == '' and p.country_code2 != '_I' and p.country_code != '_I'
                    p.country_code2 = '_I'
                end
            end

            if data.has_key?('community_ids')
                community_ids = data['community_ids']
                major_communities = Community.where(major: true).order(:fullname)
                for com in major_communities
                    if community_ids.include?(com.id)
                        if not p.communities.include?(com)
                            p.communities << com
                        end
                        p.tag_list.add(com.tagname)
                    else
                        p.communities.delete(com)
                        p.tag_list.remove(com.tagname)
                    end
                end
            end

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

    def importance
        # update importance for an item
        item_id = params[:item_id].to_i
        user_id = params[:user_id].to_i
        importance = params[:importance].to_i
        rating = Rating.where(item_id: item_id, participant_id: user_id).first
        if not rating
            rating = Rating.new(item_id: item_id, participant_id: user_id)
        end
        if rating
            rating.importance = importance
            rating.interest += 1
            rating.save
            render json: {
                status: 'success'
            }
        else
            render json: {
                status: 'error',
                message: "Rating not found"
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

    def report_complaint
        item_id = params[:item_id].to_i
        user_id = params[:user_id].to_i
        reason = params[:reason].to_s

        Rails.logger.info("api#report_complaint item:#{item_id} user:#{user_id} reason:#{reason}")

        item = Item.find_by_id(item_id)

        if item
            complaint = Complaint.new(item_id: item_id, complainer_id: user_id, poster_id: item.posted_by, reason: reason, status: 'new')
            complaint.save
            render json: {
                status: 'success'
            }
        else
            render json: {
                status: 'error',
                message: "Item not found"
            }
        end
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
            fb_uid: participant.fb_uid,
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
            auth_token: participant.authentication_token,
            religion_ids: participant.religion_ids,
            community_ids: participant.community_ids,
        }
        return info
    end 

end
