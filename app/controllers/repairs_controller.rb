class RepairsController < ApplicationController
  before_action :set_repair, only: %i[show edit update destroy]

  def index
    @repairs = Repair.includes(:car).order(date: :desc)
  end

  def show
  end

  def new
    @repair = Repair.new
    @repair.parts.build
  end

  def create
    @repair = Repair.new(repair_params)
    if @repair.save
      redirect_to @repair, notice: "Repair created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @repair.update(repair_params)
      redirect_to @repair, notice: "Repair updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @repair.destroy
    redirect_to repairs_path, notice: "Repair removed."
  end

  private

  def set_repair
    @repair = Repair.find(params[:id])
  end

  def repair_params
    params.require(:repair).permit(
      :date, :km, :notes, :car_id,
      parts_attributes: %i[id name quantity price _destroy]
    )
  end
end
