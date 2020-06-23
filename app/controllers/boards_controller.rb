# frozen_string_literal: true

class BoardsController < ApplicationController
  before_action :set_board, only: %i[show continue edit update destroy]
  skip_before_action :authenticate_user!, only: :show
  skip_verify_authorized only: :show

  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_to boards_path, alert: ex.result.message
  end

  def index
    authorize!
    @boards = current_user.boards.order(created_at: :desc)
  end

  def show
    authorize! @board
    @cards_by_type = @board.column_names.map do |column|
      [[column, ActiveModelSerializers::SerializableResource.new(@board.cards.where(kind: column)
        .includes(:author, comments: [:author]).order(created_at: :asc)).as_json]].to_h
    end.reduce({}, :merge).as_json
    @action_items = ActiveModelSerializers::SerializableResource.new(@board.action_items).as_json
    @action_item = ActionItem.new(board_id: @board.id)
    @board_creators = User.find(@board.memberships.where(role: 'creator').pluck(:user_id))
                          .pluck(:email)

    @previous_action_items = if @board.previous_board&.action_items&.any?
      ActiveModelSerializers::SerializableResource.new(@board.previous_board.action_items).as_json
                             end
    @users = User.find(@board.memberships.pluck(:user_id))
  end
  # rubocop: enable Metrics/AbcSize

  def new
    authorize!
    @board = Board.new(title: Date.today.strftime('%d-%m-%Y'))
  end

  def edit
    authorize! @board
  end

  def create
    authorize!
    @board = Board.new(board_params)
    @board.memberships.build(user_id: current_user.id, role: 'creator')

    if @board.save
      redirect_to @board, notice: 'Board was successfully created.'
    else
      render :new
    end
  end

  def update
    authorize! @board
    if @board.update(board_params)
      redirect_to edit_board_path(@board), notice: 'Board was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize! @board
    if @board.destroy
      redirect_to boards_path, notice: 'Board was successfully deleted.'
    else
      redirect_to boards_path, alert: @board.errors.full_messages.join(', ')
    end
  end

  def continue
    authorize! @board
    result = Boards::Continue.new(@board, current_user).call
    if result.success?
      redirect_to result.value!, notice: 'Board was successfully created.'
    else
      redirect_to boards_path, alert: result.failure
    end
  end

  private

  def board_params
    params.require(:board).permit(:title, :team_id, :email, :private, column_names: [])
  end

  def set_board
    @board = Board.find_by!(slug: params[:slug])
  end
end
