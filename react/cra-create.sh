#!/bin/bash
# Script to perform cleanup after using create-react-app to initialize a new react application

# Create application
mkdir "$1"
cd "$1"

# download README.md
wget -O README.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/react/README.md
sed -i "s/project-name/$1/" README.md

git init
# git remote add origin git@github.com:rbanos-mv/"$1".git
# git add README.md
# git commit -m "initial commit"
# git branch -M dev
# git push -u origin dev
# git branch -M main
# git push -u origin main
# git branch -m project-setup
# git push -u origin project-setup
npx create-react-app .

# download MIT.md, .prettierignore, .prittierrc
wget -O MIT.md https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/react/MIT.md
wget -O .prettierignore https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/react/.prettierignore
wget -O .prettierrc https://raw.githubusercontent.com/rbanos-mv/microverse-config/main/react/.prettierrc

# download linters configuration
mkdir -p .github/workflows
wget -O .github/workflows/linters.yml https://raw.githubusercontent.com/microverseinc/linters-config/master/react-redux/.github/workflows/linters.yml
wget -O .babelrc https://raw.githubusercontent.com/microverseinc/linters-config/master/react-redux/.babelrc
wget -O .eslintrc.json https://raw.githubusercontent.com/microverseinc/linters-config/master/react-redux/.eslintrc.json
wget -O .stylelintrc.json https://raw.githubusercontent.com/microverseinc/linters-config/master/react-redux/.stylelintrc.json
sed -i 's/\.env\.local/\.env\n\.env\.local/' .gitignore
sed -i 's/"name"/"homepage": ".",\n  "name"/' package.json
sed -i 's/"react-scripts eject"/"react-scripts eject",\n    "deploy": "npm run build \&\& gh-pages -d build",\n    "eslint": "npx eslint . --fix ",\n    "stylelint": "npx stylelint **\/*.{css,scss} --fix"/' package.json
mv README.md ReactCommands.md
mv README.old.md README.md

touch .env.example
echo "# The base API endpoints to which requests are made

REACT_APP_API_URL=http://
" >> .env.example

# Delete all unnecessary files
cd public
rm logo192.png logo512.png manifest.json robots.txt

# Delete unnecessary lines in index.html
sed -i '32,41d;12,26d' ./index.html

cd ../src
rm App.css App.js App.test.js index.css logo.svg reportWebVitals.js setupTests.js

# Populate App.js with general boilerplate
touch App.js
echo "function App() {
  return <div className='App'>Hello World</div>;
}

export default App;
" >> App.js

# touch index.css
# echo "@tailwind base;
# @tailwind components;
# @tailwind utilities;
# 
# " >> index.css

touch App.css
echo "* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

" >> App.css

# Delete unnecessary lines in index.js
sed -i '14,17d;5d;3d' ./index.js

# Create dir structure
mkdir components
mkdir img
mkdir pages
mkdir redux
mkdir tests

# Configure store
touch redux/configureStore.js
echo "import { configureStore } from '@reduxjs/toolkit';
// eslint-disable-next-line import/no-extraneous-dependencies
import logger from 'redux-logger';
import thunk from 'redux-thunk';
import Reducer from '.';

const middleware = [thunk];
if (process.env.NODE_ENV !== 'production') {
  middleware.push(logger);
}

const store = configureStore({
  reducer: {
    xxx: Reducer,
  },
  middleware: [thunk, logger],
});

export default store;
" >> redux/configureStore.js

# modules
mkdir modules
cd modules
touch api.js
echo "// import API_URL from './environment';

" >> api.js

touch environment.js
echo "const { REACT_APP_API_URL: API_URL } = process.env;

export default API_URL;
" >> environment.js

cd ../..
# Install packages
npm install @reduxjs/toolkit bootstrap prop-types react-bootstrap react-icons react-redux react-router-dom redux-thunk
npm install -D gh-pages prettier redux-logger react-test-renderer typescript

# Install tailwindcss
# npm install -D tailwindcss postcss autoprefixer
# npx tailwindcss init -p
# sed -i "s#content: \[\],#content: \['\./src/\*\*/\*\.{js,jsx,ts,tsx}'],#" tailwind.config.js

# Install linters
npm install -D eslint@7.x eslint-config-airbnb@18.x eslint-plugin-import@2.x eslint-plugin-jsx-a11y@6.x eslint-plugin-react@7.x eslint-plugin-react-hooks@4.x @babel/eslint-parser@7.x @babel/core@7.x  @babel/plugin-syntax-jsx@7.x  @babel/preset-react@7.x @babel/preset-react@7.x
npm install -D stylelint@13.x stylelint-scss@3.x stylelint-config-standard@21.x stylelint-csstree-validator@1.x
# Run linters
npm run stylelint
npm run eslint
npx prettier --write .

# Commit
# git add .
# git commit -m "project setup"
# git push -u origin project-setup
