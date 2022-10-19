class AlertSubscribersController < ApplicationController
  before_action :set_alert_subscriber, only: %i[edit destroy confirm]

  def new
    @alert_subscriber = AlertSubscriber.new
  end

  def create
    @alert_subscriber = AlertSubscriber.find_or_initialize_by(alert_subscriber_params)

    if @alert_subscriber.unsubscribed_at?
      @alert_subscriber.unsubscribed_at = nil
      ActiveAdmin::Comment.create(
        resource: @alert_subscriber,
        author: AdminUser.first,
        namespace: 'admin',
        body: <<~BODY
          Resubscribed via new signup.
        BODY
      )
    end

    if @alert_subscriber.save
      flash[:info] = 'Got it! We sent you a confirmation link to confirm your subscription.'

      AlertSubscriberMailer
        .confirm(@alert_subscriber)
        .deliver_now

      redirect_to :root
    else
      flash.now[:error] = "We weren't able to subscribe you: " +
        @alert_subscriber.errors.full_messages.first
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

  def confirm
    if @alert_subscriber.blank?
      flash[:error] = "We couldn't confirm your subscription. " \
        'Please check the link you clicked and try subscribing again.'
      return redirect_to :root
    elsif @alert_subscriber.confirmed_at.present?
      flash[:info] = "You've already confirmed your subscription!"
      return redirect_to :root
    end

    @alert_subscriber.confirm!

    AlertSubscriberMailer
      .subscription_confirmed(@alert_subscriber)
      .deliver_now
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
    params.fetch(:alert_subscriber).permit(:email).merge(netfile_agency: NetfileAgency.coak)
  end
end
