#!/bin/bash
# Script to create ruby on rails project with postgreSQL
if [ -z "$1" ]; then
    echo -e "\nUsage: '$0 <project name> [no-repo]' to run this command!\n"
    exit 1
fi
clear

# Create rails App
rails new "$1" --database=postgresql -T
cd "$1"

# add ".env" and "node_modules/" to .gitignore file
sed -i 's/\.env\.local/\.env\n&/' .gitignore
echo "
.env
node_modules/" >> .gitignore

# create environment variables in .env
echo "# The database credentials
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=m4st3rk3y
DEVISE_JWT_SECRET_KEY=[THIS IS A SECRET. DO NOT TELL ANYBODY.]" > .env

echo "# Set environment variables. [Remove square brackets]
DATABASE_HOST=[HOST]
DATABASE_USER=[USER]
DATABASE_PASSWORD=[PASSWORD]
DEVISE_JWT_SECRET_KEY=[SECRET]" > .env-example

# set database credentials in config/database.yml
sed -i 's/pool:.*/&\n  host: <%= ENV["DATABASE_HOST"] %>\n  username: <%= ENV["DATABASE_USER"] %>\n  password: <%= ENV["DATABASE_PASSWORD"] %>/' config/database.yml

# download MIT.md && README.md
wget -O MIT.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/rails/MIT.md
wget -O README.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/rails/README.md
sed -i "s/project-name/$1/" README.md

# download linters/test configuration
mkdir -p .github/workflows
wget -O .github/pull_request_template.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/.github/pull_request_template.md
wget -O .github/workflows/linters.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.github/workflows/linters.yml
wget -O .rubocop.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.rubocop.yml
wget -O .stylelintrc.json https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.stylelintrc.json
# delete line
sed  -i '/.*IgnoredMethods/d' ./.rubocop.yml


# Update Gemfile, install core gems,
sed -i 's/gem "rails", "~.*/&\n\n# Load environment variables\ngem "dotenv-rails", require: "dotenv\/rails-now"/' ./Gemfile
sed -i 's/gem "rails", "~.*/&\n\ngem "ffi"/' ./Gemfile

# Update Gemfile, install gems in development group,
sed -i 's/group :development do/&\n  #  Preview email\n  gem "letter_opener"/' ./Gemfile
sed -i 's/gem "letter_opener"/&\n\n  #  Linter Ruby files\n  gem "rubocop", ">= 1\.0", "< 2\.0"/' ./Gemfile

# Update Gemfile, install gems in development/test group,
sed -i 's/group :development, :test do/&\n  # Help to kill N+1 queries and unused eager loading\n  gem "bullet"/' ./Gemfile

echo 'group :test do
  # Testing framework
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "simplecov", require: false

  # Integration testing tools
  gem "capybara"
  gem "webdrivers"
end' >> Gemfile

# Update Gemfile, install gems for Authentication && Authorization
sed -i 's/gem "dotenv-rails".*/&\n\n# Authentication\ngem "devise", ">= 4.0", "< 5.0"/' ./Gemfile
sed -i 's/gem "devise".*/&\n\n# Authorization\ngem "cancancan", ">= 3.0", "< 4.0"/' ./Gemfile
sed -i 's/gem "devise".*/&\n\n# JWT authentication for devise\ngem "devise-jwt"/' ./Gemfile
sed -i 's/gem "dotenv-rails".*/&\n\n# Make Rack-based apps CORS compatible\ngem "rack-cors"/' ./Gemfile

# Update Gemfile, install gems for API documentation
sed -i 's/group :development, :test do/gem "rswag-api"\ngem "rswag-ui"\n\n&\n  gem "rswag-specs"\n/' ./Gemfile

bundle install

# Setup Bullet
echo "y" | rails g bullet:install

# Configure letter_opener
config="  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }\n  config.action_mailer.delivery_method = :letter_opener\n  config.action_mailer.perform_deliveries = true"
sed -i 's/config.action_mailer.perform_caching = false/&\n'"$config"'/' config/environments/development.rb

# Setup Rspec
rails generate rspec:install

mkdir ./spec/support
sed -i 's/# Dir\[Rails/Dir[Rails/' ./spec/rails_helper.rb
  # Configure devise
rails generate devise:install
sed -i 's/<%= yield %>/<p class="notice"><%= notice %><\/p>\n    <p class="alert"><%= alert %><\/p>\n    &/' app/views/layouts/application.html.erb
echo "
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers
" > ./spec/support/devise.rb
sed -i 's/config.reconfirmable = true/config.reconfirmable = false/' config/initializers/devise.rb

  # Generate devise views
rails g devise:views
find ./app/views/devise/ -type f -exec sed -i 's/{ method: :post }/{ "data-turbo": "false", method: :post }/' {} \;
find ./app/views/devise/ -type f -exec sed -i 's/{ method: :put }/{ "data-turbo": "false", method: :put }/' {} \;

  # Configure cancancan
rails g cancan:ability

# Configure capybara
echo "require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
end
" > ./spec/support/capybara.rb

#create database
rails db:create

# Install and run linters
npm install -S stylelint@13.x stylelint-scss@3.x stylelint-config-standard@21.x stylelint-csstree-validator@1.x
sed -i 's/"dependencies": {/"scripts": {\n    "linters": "rubocop -A -o log\/rubocop.log \&\& stylelint **\/*.{css,scss} --fix"\n  },\n  &/' ./package.json
npm run linters

if [ -z "$2" ]; then
  git remote add origin git@github.com:rbanos-mv/"$1".git
  git add README.md
  git commit -m "initial commit"
  git branch -M dev
  git push -u origin dev
  git branch -M main
  git push -u origin main
  git fetch
  git checkout dev

  # Commit
  git add .
  git commit -m "project setup"
  git push -u origin dev
else
  git add .
  git commit -m "project setup"
fi

echo "
*****************************************************************************
* IMPORTANT:
*
*****************************************************************************
"
