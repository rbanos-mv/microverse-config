#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/parse.sh $@

echo "webapp: $webapp - name: $name - push: $push - repo: $repo - withapi: $withapi"

# ###########################################################
#
# ###########################################################
if [[ $webapp == "y" ]]; then
rails new "$1" --database=postgresql -T
else
rails new "$1" --api --database=postgresql -T
fi

cd "$1"
git branch -m dev

git add README.md
  # add ".env" and "node_modules/" to .gitignore file
echo "
.env
node_modules/" >> .gitignore
git add .gitignore
git commit -m "initial commit"
git checkout -b main
git fetch
git checkout dev
echo "* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}" > public/app.css

git add .
git commit -m "initial project setup"

git checkout -b configure-app

# download MIT.md && README.md
wget -O MIT.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/MIT.md
sed -i "s/YEAR/$(date +'%Y')/;s/YOUR-NAME/$name/" MIT.md
if [[ $repo = "rbanos-mv" ]]; then
  wget -O README.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/rails/README.md
else
  wget -O README.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/rails/README-MV.md
fi
sed -i "s/project-name/$1/;s/Author1/$name/" README.md
if [[ $repo != "n" ]]; then
  sed -i "s/repo/$repo/g" README.md
fi

git add .
git commit -m "Add README and license files"

# Create vscode configuration for debugging the application
mkdir .vscode
echo '{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Rails server",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/rails",
      "args": ["server"]
    },
    {
      "name": "RSpec - active spec file only",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/bundle",
      "args": ["exec", "rspec", "-I", "${workspaceRoot}", "${file}"]
    },
    {
      "name": "RSpec - all tests",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/bundle",
      "args": ["exec", "rspec"]
    }
  ]
}' >> .vscode/launch.json

git add .vscode/launch.json
git commit -m "Configure vscode for debugging"

# Update Gemfile, install gems in development group,
  # for windows compatibility
sed -i "s/gem \"rails\", \"~.*/&\n\n# For windows\/linux compatibility\ngem 'ffi'/" Gemfile


if [[ $webapp == "n" ]]; then
  # reconfigure port
sed -i 's/{ 3000 }/{ 3001 }/' config/puma.rb
fi

  # download linters/test configuration
mkdir -p .github/workflows
wget -O .github/pull_request_template.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/.github/pull_request_template.md
wget -O .github/workflows/linters.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.github/workflows/linters.yml

  # htmlbeautifier works together with ERB Formatter
sed -i "s/group :development do/&\n  # Beautify .erb files\n  gem 'erb-formatter'\n  #  Linter Ruby files\n  gem 'rubocop', '>= 1\.0', '< 2\.0'/" Gemfile
wget -O .stylelintrc.json https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.stylelintrc.json
wget -O .rubocop.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ror/.rubocop.yml
sed  -i "s/\"/'/g;s/' /'/;s/IgnoredMethods.*/AllowedMethods: ['configure', 'delete', 'describe', 'get', 'path', 'post']/" .rubocop.yml

# Install and run linters
npm install -S stylelint@13.x stylelint-scss@3.x stylelint-config-standard@21.x stylelint-csstree-validator@1.x
sed -i 's/"dependencies": {/"scripts": {\n    "linters": "rubocop -A -o log\/rubocop.log \&\& stylelint **\/*.{css,scss} --fix"\n  },\n  &/' package.json

bundle
rubocop -A -o log/rubocop.log
git add .
git commit -m "Install tools for development: Github linters, rubocop - no stylelint"

# Install gems for API application
if [[ $withapi == "y" ]]; then
  # CORS
sed -i "s/# gem \"rack-cors\"/gem 'rack-cors'/" Gemfile
bundle
  # config CORS 
echo "# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
             headers: :any,
             expose: ['Authorization'],
             methods: %i[get post put patch delete options head]
  end
end" >| config/initializers/cors.rb

rubocop -A -o log/rubocop.log
git add .
git commit -m "Configure CORS"
fi

# Install dotenv and configure database
  # Update Gemfile, install core gems,
sed -i "s/gem 'ffi'/&\n\n# Load environment variables\ngem 'dotenv-rails', require: 'dotenv\/rails-now'/" Gemfile
sed -i "s/gem \"jbuilder\"/&\ngem 'fast_jsonapi'\n/" Gemfile
bundle

  # set database credentials in config/database.yml
sed -i 's/pool:.*/&\n  host: <%= ENV["DATABASE_HOST"] %>\n  username: <%= ENV["DATABASE_USER"] %>\n  password: <%= ENV["DATABASE_PASSWORD"] %>/' config/database.yml

echo "# The database credentials
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=m4st3rk3y
DEVISE_JWT_SECRET_KEY=$(rails secret)" > .env

echo "# Set environment variables. [Remove square brackets]
DATABASE_HOST=[HOST]
DATABASE_USER=[USER]
DATABASE_PASSWORD=[PASSWORD]
DEVISE_JWT_SECRET_KEY=[SECRET]" > .env.example

rubocop -A -o log/rubocop.log
git add .
git commit -m "Configure db credentials. Generate JWT secret"

# Install tools for development and testing
  # Update Gemfile, install gems in development/test group,
sed -i "s/group :development, :test do/&\n  # Help to kill N+1 queries and unused eager loading\n  gem 'bullet'/" Gemfile
if [[ $webapp == "y" ]]; then
# Configure letter_opener
  # Install letter opener
sed -i "s/gem 'erb-formatter'/&\n  #  Preview email\n  gem 'letter_opener'\n/" Gemfile

config="  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }\n  config.action_mailer.delivery_method = :letter_opener\n  config.action_mailer.perform_deliveries = true"
sed -i 's/config.action_mailer.perform_caching = false/&\n'"$config"'/' config/environments/development.rb
fi

bundle
# Setup Bullet
echo "y" | rails g bullet:install

echo "
group :test do
  # Testing framework
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'simplecov', require: false" >> Gemfile

if [[ $webapp == "y" ]]; then
echo "
  # Integration testing tools
  gem 'capybara'
  gem 'webdrivers'" >> Gemfile
fi
echo "end" >> Gemfile

bundle
rubocop -A -o log/rubocop.log
git add .
git commit -m "Install gems in development-test y test groups"

#######################################################
# Setup Rspec
#######################################################
rails generate rspec:install

sed -i 's/# Dir\[Rails/Dir[Rails/' spec/rails_helper.rb

mkdir ./spec/support

  # add factory_bot support to Rspec
echo "RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end" > spec/support/factory_bot.rb

#######################################################
# Setup Swagger
#######################################################
if [[ $withapi == "y" ]]; then
  # Update Gemfile, install gems for API documentation
sed -i 's/group :development, :test do/gem "rswag"\n\n&/' Gemfile
sed -i "s/gem 'rspec-rails'/&\n  gem 'rswag-specs'/" Gemfile

rails g rswag:install
  # move mounts to the bottom
sed -i -n '2{h; d}; 7{p; x;}; p' config/routes.rb
sed -i -n '2{h; d}; 6{p; x;}; p' config/routes.rb

  # Add securitySchemes component to swagger_helper.rb
comp="      components: {\n        securitySchemes: {\n          bearerAuth: {\n            type: :http,\n            scheme: :bearer,\n            bearerFormat: :JWT\n          }\n        }\n      }"
sed -i 's/]/&,\n'"$comp"'/;s/www\.example\.com/localhost:3001/' spec/swagger_helper.rb
fi

bundle
rubocop -A -o log/rubocop.log
git add .
git commit -m "Install Rspec and Swagger"

#######################################################
# Setup Devise and JWT
#######################################################
  # add gems to Gemfile
sed -i "s/gem 'dotenv-rails'.*/&\n\n# Authentication\ngem 'devise', '>= 4.0', '< 5.0'/" Gemfile
sed -i "s/gem 'devise'.*/&\n\n# Authorization\ngem 'cancancan', '>= 3.0', '< 4.0'/" Gemfile
if [[ $withapi == "y" ]]; then
sed -i "s/gem 'devise'.*/&\n\n# JWT authentication for devise\ngem 'devise-jwt'/" Gemfile
fi
bundle

  # Setup cancancan
rails g cancan:ability
sed -i 's/  end/\n    return unless user.present?\n&/' app/models/ability.rb 

  # Setup devise
rails g devise:install
if [[ $webapp == "y" ]]; then
  # add flash fields to the app layout
sed -i 's/<%= yield %>/<p class="notice"><%= notice %><\/p>\n    <p class="alert"><%= alert %><\/p>\n    &/' app/views/layouts/application.html.erb
fi

  # create User model with devise attributes
rails g model User name:string
rails g devise User
  # generate controllers
rails generate devise:controllers users

if [[ $webapp == "y" ]]; then
  # Generate devise views and customize sign up view to include name field
rails g devise:views
find ./app/views/devise/ -type f -exec sed -i 's/{ method: :post }/{ "data-turbo": "false", method: :post }/' {} \;
find ./app/views/devise/ -type f -exec sed -i 's/{ method: :put }/{ "data-turbo": "false", method: :put }/' {} \;
content='<%= f\.label :name %><br \/>\n    <%= f\.text_field :name %>\n  <\/div>\n\n  <div class=\"field\">\n    '
sed -i 's/<%= f\.label :password %>/'"$content"'&/' app/views/devise/registrations/*.html.erb

  # update user model
sed -i 's/:validatable/&, :confirmable\n\n  validates :name, presence: true/' app/models/user.rb
rails g migration AddConfirmableToUsers
echo "class AddConfirmableToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    # add_column :users, :unconfirmed_email, :string # Only if using reconfirmable
    add_index :users, :confirmation_token, unique: true
    # User.reset_column_information # Need for some types of updates, but not for update_all.
    # To avoid a short time window between running the migration and updating all existing
    # users as confirmed, do the following
    User.update_all confirmed_at: DateTime.now
    # All existing user accounts should be able to log in after this.
  end

  def down
    remove_index :users, :confirmation_token
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    # remove_columns :users, :unconfirmed_email # Only if using reconfirmable
  end
end" >| $(ls db/migrate/*add_confirmable*)
fi

if [[ $withapi == "y" ]]; then
rails g migration CreateJwtDenylist
  # add content to CreateJwtDenylist migration file
echo "class CreateJwtDenylist < ActiveRecord::Migration[7.0]
  def change
    create_table :jwt_denylist do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
    end
    add_index :jwt_denylist, :jti
  end
end" >| $(ls db/migrate/*denylist.rb)

  # serialize user model
mkdir app/serializers
echo "class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name, :email
end" > app/serializers/user_serializer.rb

  # update JwtDenylist model
echo "class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = 'jwt_denylist'
end" > app/models/jwt_denylist.rb

  # update user model
sed -i 's/:validatable/&, :jwt_authenticatable,\n         jwt_revocation_strategy: JwtDenylist\n\n  validates :name, presence: true/' app/models/user.rb
fi

rails db:drop db:create db:migrate

  # Update devise configuration
if [[ $webapp == "y" ]]; then
formats="'*\/*', :html"
else
formats=':json'
conf="\n  config\.jwt do |jwt|\n    jwt.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY', nil)\n    jwt.dispatch_requests = [\n      ['POST', %r{^\/login$}]\n    ]\n    jwt.revocation_requests = [\n      ['DELETE', %r{^\/logout$}]\n    ]\n    jwt\.expiration_time = 15\.day\.to_i\n  end\n"
sed -i '$ s/end/'"$conf"'&/' config/initializers/devise.rb
fi
sed -i "s/# config\.navigational_formats.*/config.navigational_formats = [$formats]/" config/initializers/devise.rb
sed -i 's/reconfirmable = true/reconfirmable = false/;s/# config\.navigational/config\.navigational/;s/config\.navigational.*html/&, :turbo_stream/' config/initializers/devise.rb

  # update devise controllers
echo "class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :update_allowed_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?
  load_and_authorize_resource unless: :devise_controller?

  protected

  def update_allowed_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:name, :email, :password)
    end

    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:name, :email, :password, :current_password)
    end
  end
end" >| app/controllers/application_controller.rb

if [[ $webapp == "n" ]]; then
sed -i '4,5d;2d;s/::Base/::API/' app/controllers/application_controller.rb

echo "module RackSessionFix
  extend ActiveSupport::Concern
  class FakeRackSession < Hash
    def enabled?
      false
    end
  end
  included do
    before_action :set_fake_rack_session_for_devise
    private
    def set_fake_rack_session_for_devise
      request.env['rack.session'] ||= FakeRackSession.new
    end
  end
end" > app/controllers/concerns/rack_session_fix.rb

echo "class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix

  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up sucessfully.' },
        user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }
    else
      render json: {
        status: { message: \"User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}\" }
      }, status: :unprocessable_entity
    end
  end
end" >| app/controllers/users/registrations_controller.rb

echo "class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: 'Logged in sucessfully.' },
      user: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  def respond_to_on_destroy
    if current_user
      render json: {
        status: 200,
        message: 'logged out successfully'
      }, status: :ok
    else
      render json: {
        status: 401,
        message: \"Couldn't find an active session.\"
      }, status: :unauthorized
    end
  end
end" >| app/controllers/users/sessions_controller.rb
fi

  # Configure routes for devise controllers
echo "Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ('/')
  # root to: 'home#index'

  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations'
             },
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               registration: 'signup'
             }

  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'
end" >| config/routes.rb
if [[ $webapp == "y" ]]; then
sed -i '17,19d;11,15d' config/routes.rb
fi

  # Configure RSpec to support devise
echo "RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers
end" > spec/support/devise.rb

rubocop -A -o log/rubocop.log
git add .
git commit -m "Install devise. Create User model, Generate controllers and views. Configure JWT."

#######################################################
# Setup Capybara
#######################################################
if [[ $webapp == "y" ]]; then
# Configure capybara
echo "require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
end
" > spec/support/capybara.rb

rubocop -A -o log/rubocop.log
git add .
git commit -m "Install and configure and Capybara"
fi

# This configuration MUST BE after linters
sed -i 's/#   config\.filter_run_when_matching/config\.filter_run_when_matching/' spec/spec_helper.rb

if [[ $repo != "n" ]]; then
  git remote add origin git@github.com:"$repo"/"$1".git

  if [[ $push = "y" ]]; then
    git fetch
    git checkout dev
    git push -u origin dev
    git checkout main
    git push -u origin main
    git checkout configure-app
    git push -u origin configure-app
  fi
fi

code .

echo "#####################################################"
echo "#####################################################"
