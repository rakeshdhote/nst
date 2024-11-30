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





