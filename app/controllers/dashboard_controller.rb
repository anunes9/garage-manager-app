class DashboardController < ApplicationController
  def index
    @clients_count = Client.count
    @cars_count = Car.count
    @repairs_count = Repair.count
    @repairs_this_month_count = Repair.where(date: Date.current.all_month).count
  end
end
