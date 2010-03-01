class CommentsController < ApplicationController
  
  authorize_resource
  
  respond_to :html
  
  def index
    respond_with(@comments = Comment.scoped.paginate(:page => params[:page]))
  end
  
  def show
    respond_with @comment
  end
  
  def new
    respond_with @comment = Comment.new
  end
    
  def create
    @comment = Comment.new(params[:comment])
    flash[:notice] = "Successfully created comment." if @comment.save
    respond_with @comment
  end
  
  def edit
    respond_with @comment
  end
  
  def update
    flash[:notice] = "Successfully updated comment." if @comment.update_attributes(params[:comment])
    respond_with @comment
  end
  
  def destroy
    @comment.destroy
    redirect_to comments_url, :notice => "Successfully destroyed comment."
  end
  
end
