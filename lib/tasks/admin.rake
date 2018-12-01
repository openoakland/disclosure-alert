namespace :admin do
  desc 'Create an Admin User'
  task create_user: :environment do
    require 'io/console'
    puts '============================='
    puts 'Create Admin User:'
    puts '============================='
    puts
    $stdout.write 'Email: '
    email = $stdin.gets.chomp
    $stdout.write 'Password: '
    password = $stdin.noecho(&:gets).chomp
    puts
    if AdminUser.create(email: email, password: password)
      puts 'Created!'
    end
  end
end
