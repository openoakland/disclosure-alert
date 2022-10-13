# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe 'Admin Notices Page', type: :request do
  let(:admin) { AdminUser.create!(email: 'test@example.com', password: 'superSecur3') }

  describe '#index' do
    let!(:notice) do
      Notice.create!(
        date: Date.parse('2022-10-11'),
        body: 'This is a message body!',
        creator: admin
      )
    end

    before do
      sign_in admin
      get admin_notices_path
    end

    subject { response }

    it 'renders successfully' do
      expect(subject).to be_successful
      expect(subject.body).to include(notice.body)
    end
  end

  describe '#new' do
    before do
      sign_in admin
      get new_admin_notice_path
    end

    subject { response }

    it 'renders successfully' do
      expect(subject).to be_successful
    end
  end
end
