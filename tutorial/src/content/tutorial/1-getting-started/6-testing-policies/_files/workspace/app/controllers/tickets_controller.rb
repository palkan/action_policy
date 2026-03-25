class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]

  def index
    @tickets = Ticket.includes(:user, :agent).order(created_at: :desc)
  end

  def show
    @comments = @ticket.comments.includes(:user).order(:created_at)
    @comment = Comment.new
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Current.user.tickets.build(ticket_params)

    if @ticket.save
      redirect_to @ticket, notice: "Ticket created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ticket.update(ticket_params)
      redirect_to @ticket, notice: "Ticket updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    redirect_to tickets_path, notice: "Ticket deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
    authorize! @ticket
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :escalation_level, :agent_id)
  end

  def unauthorized_redirect_path = tickets_path
end
