ActiveAdmin.register Notice do
  permit_params :body, :date

  index do
    selectable_column
    column(:date) { |notice| notice.date.strftime('%A, %B %d, %Y') }
    column(:body) { |notice| raw(notice.body) }
    column :creator
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :date, as: :datepicker, datepicker_options: {
        min_date: Date.today,
      }, input_html: { autocomplete: 'off' }
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
