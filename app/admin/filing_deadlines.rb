ActiveAdmin.register FilingDeadline do
  permit_params :date, :report_period_begin, :report_period_end, :deadline_type, :netfile_agency_id

  scope :all
  scope :future, default: true

  config.sort_order = "date_asc"
  config.create_another = true

  index do
    selectable_column
    column(:date)
    column(:report_period_begin)
    column(:report_period_end)
    column(:deadline_type)
    column(:netfile_agency_id)
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input(:date,
              as: :datepicker,
              datepicker_options: { min_date: Date.today - 1 },
              input_html: { autocomplete: 'off' },
              hint: '(For "Within 24 hours", use the beginning of the period.)'
             )
      f.input :report_period_begin, as: :datepicker
      f.input :report_period_end, as: :datepicker

      deadline_types = FilingDeadline.deadline_types.map do |type, value|
        [I18n.t("activerecord.filing_deadline.deadline_type.#{type}"), type]
      end
      f.input :deadline_type, as: :select, collection: deadline_types

      netfile_agencies = NetfileAgency.each_supported_agency.map do |agency|
        [agency.name, agency.netfile_id]
      end
      f.input :netfile_agency_id, as: :select, collection: netfile_agencies, hint: 'Only select an option here if this deadline pertains to a specific jurisdiction (i.e. is not a statewide deadline).'
    end
    f.actions
  end

end
