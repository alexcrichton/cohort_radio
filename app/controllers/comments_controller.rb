class CommentsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    respond_with(@comments = @song.comments.paginate(:page => params[:page]))
  end
  
  def show
    respond_with @comment
  end
  
  def new
    respond_with @comment = @song.comments.build
  end
    
  def create
    @comment = @song.comments.new(params[:comment])
    @comment.user = current_user 
    
    if @comment.save
      flash[:notice] = "Successfully created comment."
      if request.xhr?
        render @comment
      else
        redirect_to @song
      end
    else      
      if request.xhr?
        render :text => @comment.errors 
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    respond_with @comment
  end
  
  def update
    if @comment.update_attributes(params[:comment])
      if request.xhr?
        render @comment
      else
        flash[:notice] = "Successfully updated comment."
        redirect_to @song
      end
    else
      if request.xhr?
        render :text => @comment.errors
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    @comment.destroy
    if request.xhr?
      render :text => 'success'
    else
      redirect_to @song, :notice => "Successfully destroyed comment."
    end
  end
  
end
