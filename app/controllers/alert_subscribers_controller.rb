class AlertSubscribersController < ApplicationController
  def new
    @alert_subscriber = AlertSubscriber.new
  end

  def create
    @alert_subscriber = AlertSubscriber.new(alert_subscriber_params)

    if @alert_subscriber.save
      flash[:info] = 'Subscribed!'

      redirect_to :root
    else
      render :new
    end
  end

  private

  def alert_subscriber_params
    params.fetch(:alert_subscriber).permit(:email)
  end
end
