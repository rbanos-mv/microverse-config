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
node_modules/" >> .gitignore

# configure database
touch .env
echo "# The database credentials
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=m4st3rk3y" >> .env
cp .env .env.example

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

# Update Gemfile, install
  # - dotenv-rails,
  # - rails-controller-testing
  # - rspec-rails
  # - rubocop
sed -i 's/gem "rails", "~.*/&\n\ngem "dotenv-rails", require: "dotenv\/rails-now"/;t;s/gem "debug".*/&\n  gem "rails-controller-testing"\n  gem "rspec-rails", ">= 5.0", "< 6.0"/;t;s/gem \"spring\"/&\n\n  # linters\n  gem "rubocop", ">= 1\.0", "< 2\.0"/' ./Gemfile

bundle install
#npm install -S stylelint@13.x stylelint-scss@3.x stylelint-config-standard@21.x stylelint-csstree-validator@1.x

# Setup Rspec
rails generate rspec:install

#create database
rails db:create

# Run linters
rubocop -A
npx stylelint **/*.{css,scss} --fix

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
fi
