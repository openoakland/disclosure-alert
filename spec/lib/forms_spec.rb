require 'rails_helper'

RSpec.describe Forms::BaseForm do
  describe '#i18n_key' do
    context 'for a known form' do
      let(:filing) { Filing.new(form: 23, title: 'FPPC Form 410') }
      let(:form) { Forms.from_filings([filing]).first }

      it 'returns the correct label for the type' do
        expect(form.i18n_key).to eq('forms.410')
      end
    end

    context 'with an unknown form' do
      let(:filing) { Filing.new(form: 999, title: 'FPPC Form 999') }
      let(:form) { Forms.from_filings([filing]).first }

      it 'returns the unknown form label' do
        expect(form.i18n_key).to eq('forms.unknown')
      end
    end
  end
end
