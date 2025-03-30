require 'rails_helper'

RSpec.describe Forms::BaseForm do
  def load_filings_from_file(fixture_csv)
    # To create a filings fixture, run in psql:
    #
    # \copy (SELECT id, form, title, amendment_sequence_number, amended_filing_id, contents
    # FROM filings WHERE id IN (...))
    # TO 'spec/fixtures/filing_contents/test_case_filename.csv'
    # DELIMITER ',' CSV HEADER
    CSV.open(Rails.root.join("spec", "fixtures", "filing_contents", fixture_csv), "r", headers: :first_row).map do |csv|
      Filing.create(
        id: csv["id"],
        form: csv["form"],
        title: csv["title"],
        amendment_sequence_number: csv["amendment_sequence_number"],
        amended_filing_id: csv["amended_filing_id"],
        contents: JSON.parse(csv["contents"])
      )
    end
  end

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

  describe '.combine_forms' do
    let(:filing1) { Filing.new(form: 36, title: 'Oaklanders for a better Oakland', contents: JSON.parse(<<~JSON)) }
      [
        {"form_Type":"F496P3","tran_Dscr":"","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":25000.0,"cand_NamL":null,"sup_Opp_Cd":null,"bal_Name":null,"bal_Num":null,"tran_NamL":"Service Employees International Union Local 1021 Candidate PAC","tran_NamF":"","tran_City":"Sacramento","tran_Zip4":"95814","tran_Emp":"","tran_Occ":"","tran_Amt1":25000.0,"tran_Amt2":0.0,"entity_Cd":"SCC","cmte_Id":"1296948"},
        {"form_Type":"F496","tran_Dscr":"NEWSPAPER ADVERTISEMENTS","tran_Date":"2020-10-14T00:00:00.0000000-07:00","calculated_Amount":3737.5,"cand_NamL":"ExampleCandidate","sup_Opp_Cd":"S","bal_Name":"","bal_Num":"","tran_NamL":null,"tran_NamF":null,"tran_City":null,"tran_Zip4":null,"tran_Emp":null,"tran_Occ":null,"tran_Amt1":3737.5,"tran_Amt2":null,"entity_Cd":null,"cmte_Id":null}
      ]
    JSON
    let(:filing2) { Filing.new(form: 36, title: 'Oaklanders for a better Oakland', contents: JSON.parse(<<~JSON)) }
      [
        {"form_Type":"F496P3","tran_Dscr":"","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":25000.0,"cand_NamL":null,"sup_Opp_Cd":null,"bal_Name":null,"bal_Num":null,"tran_NamL":"Service Employees International Union Local 1021 Candidate PAC","tran_NamF":"","tran_City":"Sacramento","tran_Zip4":"95814","tran_Emp":"","tran_Occ":"","tran_Amt1":25000.0,"tran_Amt2":0.0,"entity_Cd":"SCC","cmte_Id":"1296948"},
        {"form_Type":"F496","tran_Dscr":"PHONE CALLS","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":5830.5,"cand_NamL":"OtherCandidate","sup_Opp_Cd":"S","bal_Name":"","bal_Num":"","tran_NamL":null,"tran_NamF":null,"tran_City":null,"tran_Zip4":null,"tran_Emp":null,"tran_Occ":null,"tran_Amt1":5830.5,"tran_Amt2":null,"entity_Cd":null,"cmte_Id":null}
      ]
    JSON

    context 'with two 496 IE forms 496 IE forms with different expenditures' do
      it 'merges the forms together' do
        result = Forms.combine_forms(Forms.from_filings([filing1, filing2]))
        expect(result.length).to eq(1)
        combined_form = result.first
        expect(combined_form).to be_a(Forms::Form496Combined)
        expect(combined_form.contributions.length).to eq(1)
        expect(combined_form.expenditures.length).to eq(2)
      end
    end

    context 'when one of the forms is amended and the other is not' do
      let(:original_filing) { Filing.create(form: 36, title: 'Oaklanders for a better Oakland', netfile_agency: NetfileAgency.coak, contents: JSON.parse(<<~JSON)) }
        [
          {"form_Type":"F496P3","tran_Dscr":"","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":25000.0,"cand_NamL":null,"sup_Opp_Cd":null,"bal_Name":null,"bal_Num":null,"tran_NamL":"Service Employees International Union Local 1021 Candidate PAC","tran_NamF":"","tran_City":"Sacramento","tran_Zip4":"95814","tran_Emp":"","tran_Occ":"","tran_Amt1":25000.0,"tran_Amt2":0.0,"entity_Cd":"SCC","cmte_Id":"1296948"},
          {"form_Type":"F496","tran_Dscr":"PHONE CALLS","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":5830.5,"cand_NamL":"OtherCandidate","sup_Opp_Cd":"S","bal_Name":"","bal_Num":"","tran_NamL":null,"tran_NamF":null,"tran_City":null,"tran_Zip4":null,"tran_Emp":null,"tran_Occ":null,"tran_Amt1":5830.5,"tran_Amt2":null,"entity_Cd":null,"cmte_Id":null}
        ]
      JSON

      before do
        filing2.update(amendment_sequence_number: '1', amended_filing_id: original_filing.id)
      end

      it 'does not merge the forms together' do
        forms = Forms.combine_forms(Forms.from_filings([filing1, filing2]))
        expect(forms.length).to eq(2)
        expect(forms.first).to be_a(Forms::Form496)
        expect(forms.first).not_to be_amendment
        expect(forms.second).to be_a(Forms::Form496)
        expect(forms.second).to be_amendment
      end
    end

    context 'when one of the 496 forms is an amended version of the other one' do
      let(:filing1) { super().tap(&:save) }
      let(:filing2) { super().tap(&:save) }
      let(:filing3) { Filing.create(form: 36, title: 'Oaklanders for a better Oakland', netfile_agency: NetfileAgency.coak, contents: JSON.parse(<<~JSON)) }
        [
          {"form_Type":"F496P3","tran_Dscr":"","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":35000.0,"cand_NamL":null,"sup_Opp_Cd":null,"bal_Name":null,"bal_Num":null,"tran_NamL":"Service Employees International Union Local 1021 Candidate PAC","tran_NamF":"","tran_City":"Sacramento","tran_Zip4":"95814","tran_Emp":"","tran_Occ":"","tran_Amt1":25000.0,"tran_Amt2":0.0,"entity_Cd":"SCC","cmte_Id":"1296948"},
          {"form_Type":"F496","tran_Dscr":"PHONE CALLS","tran_Date":"2020-10-09T00:00:00.0000000-07:00","calculated_Amount":5830.5,"cand_NamL":"OtherCandidate","sup_Opp_Cd":"S","bal_Name":"","bal_Num":"","tran_NamL":null,"tran_NamF":null,"tran_City":null,"tran_Zip4":null,"tran_Emp":null,"tran_Occ":null,"tran_Amt1":5830.5,"tran_Amt2":null,"entity_Cd":null,"cmte_Id":null}
        ]
      JSON
      let(:forms) { Forms.from_filings([filing1, filing2, filing3]) }

      before do
        filing2.update(amended_filing_id: filing1.id, amendment_sequence_number: '1')
        filing3.update(amended_filing_id: filing1.id, amendment_sequence_number: '2')
      end

      it 'deletes the previous versions of that form' do
        result = Forms.combine_forms(forms)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Forms::Form496)
        expect(result.first).to have_attributes(amendment_sequence_number: '2')
      end
    end

    context "with two 497's from the same filer" do
      let(:filings) { load_filings_from_file("497_combine_same_filer.csv") }

      it "combines the forms together" do
        result = Forms.combine_forms(Forms.from_filings(filings))
        expect(result.length).to eq(1)
        combined_form = result.first
        expect(combined_form).to be_a(Forms::Form497Combined)
        expect(combined_form.count_contributions_received).to eq(2)
        expect(combined_form.amount_contributions_received).to eq(20_555)
      end

      context 'when one of the forms is amended and the other is not' do
        let(:filings) { load_filings_from_file("497_combine_with_one_amended.csv") }

        it 'does not combine the forms' do
          forms = Forms.combine_forms(Forms.from_filings(filings))
          expect(forms.length).to eq(2)
          expect(forms.first).to be_a(Forms::Form497)
          expect(forms.first).to be_amendment
          expect(forms.second).to be_a(Forms::Form497)
          expect(forms.second).not_to be_amendment
        end
      end
    end
  end
end
