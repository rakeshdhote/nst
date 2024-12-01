#!/bin/bash

# nextjs
npx create-next-app@latest
npx create-next-app@latest my-project --typescript --tailwind --eslint --app-router

#shadcn init
pnpm dlx shadcn@latest init -d

# add components
pnpm dlx shadcn@latest add card button textarea card alert sidebar dropdown

#shadcn theme
pnpm add next-themes



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
git push -u origin maingit rm .github/workflows/release.yml
git commit -m "Remove workflow file to push first"
git push -u origin main
git tag v0.0.1
git push origin v0.0.1


# https://thatgurjot.com/til/tauri-auto-updater/
pnpm run tauri signer generate -- -w ~/.tauri/myapp.key
# create .env

###################
# github actions windows
# Error: microsoft defender smartscreen prevented an unrecognized app from starting 
# created windows-build.yml
# Set up code signing using Azure Key Vault:
# Create an Azure account if you don't have one
# Create a Key Vault in Azure
# Generate or import a code signing certificate
# Create an App Registration in Azure AD for authentication
# Add these secrets to your GitHub repository:
# AZURE_KEY_VAULT_URI: Your Azure Key Vault URI
# AZURE_CLIENT_ID: App Registration client ID
# AZURE_TENANT_ID: Azure tenant ID
# AZURE_CLIENT_SECRET: App Registration client secret
# CERTIFICATE_NAME: Name of your certificate in Key Vault
# TAURI_PRIVATE_KEY: Your Tauri update key
# TAURI_KEY_PASSWORD: Password for the Tauri key

# For macOS builds:
# Required secrets for notarization:
# APPLE_CERTIFICATE: Base64 encoded Developer ID certificate
# APPLE_CERTIFICATE_PASSWORD: Certificate password
# APPLE_ID: Your Apple ID email
# APPLE_TEAM_ID: Your Team ID
# APPLE_PASSWORD: App-specific password
# For detailed instructions on macOS notarization,
# see docs/macos-notarization-setup.md

# or generate local certificate
# For Windows builds:
# If you want to sign the Windows builds, you'll need to set up one of these options in your repository secrets:
# Option 1: Local Certificate
# WINDOWS_SIGN_CERT: Base64-encoded PFX certificate
# WINDOWS_SIGN_CERT_PASSWORD: Certificate password
# For detailed instructions on generating Windows certificates,
# see docs/windows-signing-setup.md

# Option 2: Azure Key Vault
# AZURE_KEY_VAULT_URI
# AZURE_CLIENT_ID
# AZURE_TENANT_ID
# AZURE_CLIENT_SECRET

# For detailed instructions on setting up Azure Key Vault for code signing,
# see docs/azure-signing-setup.md

###################
