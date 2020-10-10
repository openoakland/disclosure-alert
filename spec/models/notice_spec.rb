# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notice do
  describe '#save' do
    let(:admin_user) { AdminUser.create(email: 'tomdooner+test@example.com') }
    let(:notice_body) { '' }
    let(:notice_date) { Date.tomorrow }
    let(:notice) { Notice.new(creator: admin_user, body: notice_body, date: notice_date) }

    describe 'with invalid HTML' do
      let(:notice_body) { 'foo<script>bar</script>' }

      it 'strips it out' do
        expect(notice.save).to eq(true)
        notice.reload
        expect(notice.body).not_to include('<script>')
        expect(notice.body).to eq('foobar')
      end
    end
  end
end
