class CarsController < ApplicationController
  before_action :set_car, only: %i[show edit update destroy]

  def index
    @cars = Car.includes(:client).order(:plate)
  end

  def show
  end

  def search
    @query = params[:q].to_s.strip
    @cars = if @query.length >= 2
      Car.includes(:client).where("plate ILIKE ?", "%#{@query}%").order(:plate)
    else
      Car.none
    end
  end

  def new
    @car = Car.new(client_id: params[:client_id])
  end

  def create
    @car = Car.new(car_params)
    if @car.save
      redirect_to @car, notice: t("cars.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @car.update(car_params)
      redirect_to @car, notice: t("cars.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @car.destroy
    redirect_to cars_path, notice: t("cars.destroyed")
  end

  private

  def set_car
    @car = Car.find(params[:id])
  end

  def car_params
    params.require(:car).permit(:brand, :model, :plate, :vin, :motor, :notes, :client_id)
  end
end
