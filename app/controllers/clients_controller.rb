class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @clients = Client.order(:name)
  end

  def show
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: t("clients.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: t("clients.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: t("clients.destroyed")
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :phone)
  end
end
