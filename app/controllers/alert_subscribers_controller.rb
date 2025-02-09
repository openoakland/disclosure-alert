class AlertSubscribersController < ApplicationController
  before_action :set_alert_subscriber, only: %i[edit destroy confirm update]

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

  def update
    @alert_subscriber.assign_attributes(alert_subscriber_params)

    AlertSubscriber.transaction do
      ActiveAdmin::Comment.create(
        resource: @alert_subscriber,
        author: AdminUser.first,
        namespace: 'admin',
        body: <<~BODY
          User modified attributes:
          #{@alert_subscriber.changes.map { |attribute, (old, new)| "* #{attribute} from #{old} to #{new}" }.join("\n")}
        BODY
      )

      if @alert_subscriber.save
        flash[:info] = 'Successfully updated your subscription settings.'
        redirect_to edit_alert_subscriber_path(@alert_subscriber, token: @alert_subscriber.token)
      end
    end
  end

  def destroy
    if @alert_subscriber.unsubscribe!
      flash[:info_html] = <<~EOF
        You've been successfully unsubscribed! Could you
        <a href="https://docs.google.com/forms/d/e/1FAIpQLSeRo2RUDjd9rbv1azDsiYezliKr0JbxbTfWvWgEBbKrUsklZA/viewform" target="_blank">
        leave us some quick feedback
        </a>
        to improve the service for others?
      EOF
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
    params.fetch(:alert_subscriber).permit(:email, :subscription_frequency).merge(netfile_agency: NetfileAgency.coak)
  end
end
