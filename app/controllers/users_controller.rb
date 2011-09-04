class UsersController < ApplicationController

  authorize_resource

  respond_to :html, :except => :search
  respond_to :json, :only => :search

  skip_before_filter :verify_authenticity_token, :only => [:pusher_auth]

  def search
    @users = User.search(params[:q]).limit(params[:limit])

    respond_with @users do |format|
      format.json {
        render :json => @users.map{ |u|
          {:id => u.id, :name => u.name, :email => u.email}
        }
      }
    end
  end

  def pusher_auth
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    render :json => response
  end

end
