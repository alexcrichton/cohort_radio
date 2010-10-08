class UsersController < ApplicationController

  authorize_resource

  respond_to :html, :except => :search
  respond_to :json, :only => :search

  def home
    redirect_to current_user ? playlists_path : new_user_session_path
  end

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

end
