namespace :db do
  desc "Load the seed data from db/seeds.rb"
  task :seed do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end
end