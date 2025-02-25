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

    describe 'with form type = 497' do
      let(:form_id) { 39 }
      it { expect(subject).to eq('497') }
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

  describe '#sort_forms' do
    let(:forms) do
      Forms.from_filings([
        Filing.create(form: 23, title: 'Form 410'),
        Filing.create(form: 30, title: 'Form 460'),
        Filing.create(form: 23, title: 'Form 410'),
        Filing.create(form: 39, title: 'Form 497', filer_id: 123),
        Filing.create(form: 0, title: 'Some Other Form'),
        Filing.create(form: 215, title: 'Form 700'),
        Filing.create(form: 36, title: 'Form 496'),
        Filing.create(form: 39, title: 'Form 497', filer_id: 456),
        Filing.create(form: 235, title: 'Lobbyist Registration'),
      ])
    end

    it 'sorts in order of descending interestingness' do
      sorted = helper.sort_forms(forms)
      expect(sorted[0]).to have_attributes(form: "39", title: 'Form 497', filer_id: "123")
      expect(sorted[1]).to have_attributes(form: "39", title: 'Form 497', filer_id: "456")
      expect(sorted[2]).to have_attributes(form: "36", title: 'Form 496')
      expect(sorted[3]).to have_attributes(form: "30", title: 'Form 460')
      expect(sorted[4]).to have_attributes(form: "23", title: 'Form 410')
      expect(sorted[5]).to have_attributes(form: "23", title: 'Form 410')
      expect(sorted[6]).to have_attributes(form: "215", title: 'Form 700')
      expect(sorted[7]).to have_attributes(form: "235", title: 'Lobbyist Registration')
      expect(sorted[8]).to have_attributes(form: "0", title: 'Some Other Form')
    end
  end

  describe '#amended_value_if_different' do
    let(:filing_contents) do
      [
        { 'form_Type' => 'F460', 'line_Item' => '5', 'amount_A' => 1000 }, # total contributions received
      ]
    end
    let(:filing) { Filing.create(filer_id: 123, form: 30, contents: filing_contents, netfile_agency: NetfileAgency.coak) }
    let(:form) { Forms.from_filings([filing]).first }

    it 'returns the value when there is no amended form' do
      expect(helper.amended_value_if_different(form, :total_contributions_received)).to eq('$1,000')
    end

    context 'with an amended form' do
      let(:amended_filing_contents) { filing_contents.dup.tap { |c| c[0]['amount_A'] = 2000 } }
      let(:filing_amendment) { Filing.create(form: 30, amended_filing_id: filing.id, contents: amended_filing_contents, netfile_agency: NetfileAgency.coak) }
      let(:form_amendment) { Forms.from_filings([filing_amendment]).first }

      it 'returns an amended value' do
        expect(helper.amended_value_if_different(form_amendment, :total_contributions_received))
          .to eq('$2,000 (amended from $1,000)')
      end

      context 'when the amended value is the same' do
        let(:amended_filing_contents) { filing_contents }

        it 'returns the unamended value' do
          expect(helper.amended_value_if_different(form, :total_contributions_received)).to eq('$1,000')
        end
      end
    end
  end

  describe '#deduplicate_deadlines' do
    context 'when there are duplicates (one with netfile_agency_id and one without)' do
      let(:deadlines) do
        [
          FilingDeadline.create(date: '2024-07-31', report_period_end: '2024-03-30', netfile_agency_id: NetfileAgency.coak.netfile_id),
          FilingDeadline.create(date: '2024-07-31', report_period_end: '2024-06-30')
        ]
      end

      it 'removes the FilingDeadline without the netfile_agency_id' do
        deduplicated = helper.deduplicate_deadlines(deadlines)
        expect(deduplicated.length).to eq(1)
        expect(deduplicated).to match_array([deadlines.first])
      end
    end
  end
end
