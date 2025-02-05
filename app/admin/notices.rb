ActiveAdmin.register Notice do
  permit_params :body, :date, :informational

  index do
    selectable_column
    column(:date) { |notice| notice.date.strftime('%A, %B %d, %Y') }
    column(:informational)
    column(:body) { |notice| raw(notice.body) }
    column :creator
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :date, as: :datepicker, datepicker_options: {
        min_date: Date.today - 1,
      }, input_html: { autocomplete: 'off' }, hint: "Note: The date should be the date of the *filings* (i.e. the day before the notice will be sent). This date should match the subject line of the email."
      f.input :informational
      f.input :body
    end
    f.actions
  end

  controller do
    after_build do |notice|
      notice.creator = current_admin_user
    end
  end
end
