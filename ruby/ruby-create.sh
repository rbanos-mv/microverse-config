#!/bin/bash
# Script to create ruby project

# Create application
mkdir "$1"
cd "$1"

# download MIT.md && README.md
wget -O MIT.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/ruby/MIT.md
wget -O README.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/ruby/README.md
sed -i "s/project-name/$1/" README.md

git init
git remote add origin git@github.com:rbanos-mv/"$1".git
git add README.md
git commit -m "initial commit"
git branch -M dev
git push -u origin dev
git branch -M main
git push -u origin main
git branch -m project-setup
git push -u origin project-setup

# download linters/test configuration
mkdir -p .github/workflows
wget -O .github/workflows/linters.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ruby/.github/workflows/linters.yml
wget -O .github/workflows/tests.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ruby/.github/workflows/tests.yml
wget -O .rubocop.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/ruby/.rubocop.yml
# download .gitignore for Ruby
wget -O .gitignore https://raw.githubusercontent.com/github/gitignore/main/Ruby.gitignore
sed -i "s/# \.rubocop/\.rubocop/" .gitignore

# create Gemfile && install
echo "source 'https://rubygems.org'

gem 'fileutils', '1.6.0'
gem 'json', '2.6.2'
gem 'rspec' 
gem 'rubocop', '>= 1.0', '< 2.0'
" >> Gemfile
bundle install
echo "finished bundle install"

mkdir classes
mkdir json
mkdir modules
mkdir schema
mkdir spec

# Commit
git add .
git commit -m "project setup"
git push -u origin project-setup

