---
type: tutorial
openInStackBlitz: false
prepareCommands:
  - ['node scripts/ready.js off', 'Mark Rails VM as not ready']
  - ['npm install', 'Preparing Ruby runtime']
  - ['node scripts/ready.js on', 'Mark Rails VM as ready']
previews: false
filesystem:
  watch: ['/*.json', '/workspace/**/*']
terminal:
  open: true
  activePanel: 0
  panels:
    - type: terminal
      id: 'cmds'
      title: 'Command Line'
      allowRedirects: true
    - ['output', 'Setup Logs']
---
