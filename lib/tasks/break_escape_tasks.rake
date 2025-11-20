namespace :break_escape do
  desc "Load BreakEscape seed data"
  task seed: :environment do
    load File.join(BreakEscape::Engine.root, 'db', 'seeds.rb')
  end
end

