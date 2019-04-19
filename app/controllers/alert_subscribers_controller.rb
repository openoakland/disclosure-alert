class AlertSubscribersController < ApplicationController
  before_action :set_alert_subscriber, only: %i[edit destroy]

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

  def edit; end

  def destroy
    if @alert_subscriber.unsubscribe!
      flash[:info] = 'You have been successfully unsubscribed!'
      return redirect_to :root
    end
  end

  private

  def set_alert_subscriber
    @alert_subscriber = AlertSubscriber.find(params[:id])

    unless @alert_subscriber.token == params[:token]
      flash[:error] = 'Forbidden'
      redirect_to root_url
    end
  end

  def alert_subscriber_params
    params.fetch(:alert_subscriber).permit(:email)
  end
end
