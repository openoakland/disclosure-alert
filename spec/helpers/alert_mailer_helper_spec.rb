# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertMailerHelper do
  describe '#form_number_html' do
    let(:form_id) { nil }
    let(:form_title) { '' }
    let(:form) { Filing.new(form: form_id, title: form_title) }

    subject { helper.form_number_html(form) }

    describe 'with form type = 460' do
      let(:form_id) { Filing::FORM_IDS['460'] }
      it { expect(subject).to eq('460') }
    end

    describe 'with form type = 497 LCR' do
      let(:form_id) { Filing::FORM_IDS['497 LCR'] }
      it { expect(subject).to eq('497 <sub>LCR</sub>') }
      it { expect(subject).to be_html_safe }
    end

    describe 'with a form of an unknown number' do
      let(:form_title) { 'FPPC Form 123' }
      it { expect(subject).to eq('123') }
    end

    describe 'with a lobbyist form' do
      let(:form_id) { Filing::FORM_IDS['LOB'] }
      it { expect(subject).to eq('LOB') }
    end
  end
end
