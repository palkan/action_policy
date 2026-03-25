class CommentsController < ApplicationController
  before_action :set_ticket
  before_action :set_comment, only: %i[destroy]
  before_action :require_author_or_admin, only: %i[destroy]

  def create
    @comment = @ticket.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to @ticket, notice: "Comment added."
    else
      redirect_to @ticket, alert: "Comment can't be blank."
    end
  end

  def destroy
    @comment.destroy
    redirect_to @ticket, notice: "Comment deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_comment
    @comment = @ticket.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :internal)
  end

  def require_author_or_admin
    unless @comment.user == Current.user || Current.user.admin?
      redirect_to @ticket, alert: "Not authorized"
    end
  end
end
