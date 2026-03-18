---
type: part
title: Getting started with Action Policy
template: rails-app
prepareCommands:
  - ['node scripts/ready.js off', 'Mark Rails VM as not ready']
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/rails.js db:prepare', 'Prepare development database']
  - ['node scripts/ready.js on', 'Mark Rails VM as ready']
---
