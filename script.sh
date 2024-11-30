#!/bin/bash

# nextjs
npx create-next-app@latest

#shadcn init
pnpm dlx shadcn@latest init -d

# add components
pnpm dlx shadcn@latest add card button textarea card alert

# install tauri2.0
pnpm add -D @tauri-apps/cli@latest

# init tauri
pnpm tauri init

#dev
pnpm tauri dev

# git init
git init

# git add
git add .
git commit -m "init"
git remote add origin https://github.com/rakeshdhote/nst.git
git branch -M main
git push -u origin main

# git tag and push
git tag v1.0.0 && git push origin v1.0.0
