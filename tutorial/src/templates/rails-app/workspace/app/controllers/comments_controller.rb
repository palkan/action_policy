class CommentsController < ApplicationController
  before_action :set_ticket

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
    @comment = @ticket.comments.find(params[:id])
    @comment.destroy
    redirect_to @ticket, notice: "Comment deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def comment_params
    params.require(:comment).permit(:body, :internal)
  end
end
