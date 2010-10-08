class UsersController < ApplicationController

  authorize_resource

  respond_to :html, :except => :search
  respond_to :json, :only => :search

  def home
    redirect_to current_user ? playlists_path : new_user_session_path
  end

  def adminize
    @user.admin = params[:user][:admin]
    Notifier.send_later :deliver_admin_notification, @user if @user.save
    render :text => (@user.admin ? 'Adminized' : 'Revoked')
  end

  def search
    if params[:q].blank?
      @users = []
    else
      @users = User.search(params[:q]).limit(params[:limit])
    end

    respond_with @users do |format|
      format.json {
        render :json => @users.map{ |u|
          {:id => u.id, :name => u.name, :email => u.email}
        }
      }
    end
  end

end
