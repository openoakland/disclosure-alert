# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertMailerHelper do
  describe '#form_number_html' do
    let(:form_id) { nil }
    let(:form_title) { '' }
    let(:form) { Filing.new(form: form_id, title: form_title) }

    subject { helper.form_number_html(form) }

    describe 'with form type = 460' do
      let(:form_id) { 30 }
      it { expect(subject).to eq('460') }
    end

    describe 'with form type = 497 LCR' do
      let(:form_id) { 39 }
      it { expect(subject).to eq('497 <sub>LCR</sub>') }
      it { expect(subject).to be_html_safe }
    end

    describe 'with a form of an unknown number' do
      let(:form_title) { 'FPPC Form 123' }
      it { expect(subject).to eq('123') }
    end

    describe 'with a lobbyist form' do
      let(:form_id) { 236 }
      it { expect(subject).to eq('LBQ') }
    end
  end

  describe '#format_position_title' do
    let(:title_position) { 'Some Position' }
    let(:title_agency) { 'Some Agency' }
    let(:title_object) do
      {
        position: title_position,
        agency: title_agency,
        division_board_district: 'Some Board or District',
      }
    end

    subject { format_position_title(title_object) }

    it { is_expected.to eq('Some Position, Some Agency') }

    context 'with a Commissioner position' do
      let(:title_position) { 'Commissioner' }
      it { is_expected.to eq('Commissioner, Some Board or District') }
    end
  end

  describe '#sort_filing_groups' do
    let(:filing_groups) do
      {
        'Some form' => [],
        'Other forms' => [],
        'Foo forms' => [],
      }
    end

    subject { helper.sort_filing_groups(filing_groups) }

    it 'sorts "Other" at the end' do
      expect(subject).to eq([
        ['Foo forms', []],
        ['Some form', []],
        ['Other forms', []],
      ])
    end
  end
end
