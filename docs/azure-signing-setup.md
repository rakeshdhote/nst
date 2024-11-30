# Setting up Azure Key Vault for Code Signing

This guide will walk you through setting up Azure Key Vault for code signing your Windows applications.

## 1. Create an Azure Account

1. Go to [Azure Portal](https://portal.azure.com)
2. If you don't have an account:
   - Click "Start Free"
   - Follow the registration process
   - You'll need a Microsoft account or can create one
   - A credit card is required for verification (but won't be charged for free tier)

## 2. Create a Key Vault

1. In the Azure Portal:
   - Click "Create a resource"
   - Search for "Key Vault"
   - Click "Create"

2. Fill in the basics:
   ```
   Subscription: [Your subscription]
   Resource group: Create new (e.g., "nst-signing")
   Key vault name: [unique name, e.g., "nst-code-signing"]
   Region: [Choose nearest region]
   Pricing tier: Standard
   ```

3. Review + Create:
   - Click "Review + Create"
   - Click "Create"
   - Wait for deployment to complete

## 3. Generate/Import Code Signing Certificate

### Option A: Import Existing Certificate
If you have a code signing certificate from a trusted CA:

1. Convert your certificate to PFX format if not already
2. In Key Vault:
   - Go to "Certificates"
   - Click "Import"
   - Upload your PFX file
   - Name: "nst-code-signing-cert"
   - Set content type: "application/x-pkcs12"

### Option B: Generate New Certificate
If you don't have a certificate:

1. In Key Vault:
   - Go to "Certificates"
   - Click "Generate/Import"
   - Subject: "CN=NST Tech"
   - Content Type: "pkcs12"
   - Lifetime Action: Auto-renew
   - Validity Period: 12 months
   - Certificate Type: "CodeSigning"
   - Click "Create"

## 4. Create App Registration

1. In Azure Portal:
   - Go to "Azure Active Directory"
   - Click "App registrations"
   - Click "New registration"

2. Register the application:
   ```
   Name: "NST Code Signing App"
   Supported account types: "Single tenant"
   Redirect URI: (Leave blank)
   ```
   - Click "Register"

3. Get Application (client) ID:
   - Copy and save the "Application (client) ID"
   - Copy and save the "Directory (tenant) ID"

4. Create Client Secret:
   - Click "Certificates & secrets"
   - Click "New client secret"
   - Description: "GitHub Actions"
   - Expiry: 24 months
   - Click "Add"
   - IMPORTANT: Copy the secret value immediately (you won't see it again)

## 5. Configure Key Vault Access

1. In your Key Vault:
   - Go to "Access policies"
   - Click "Add Access Policy"

2. Configure the policy:
   ```
   Certificate permissions: Get, List
   Key permissions: Get, List, Sign
   Secret permissions: Get, List
   Select principal: [Search and select your App Registration]
   ```
   - Click "Add"

## 6. Add Secrets to GitHub

1. In your GitHub repository:
   - Go to "Settings" → "Secrets and variables" → "Actions"
   - Click "New repository secret"

2. Add these secrets:
   ```
   AZURE_KEY_VAULT_URI: https://[your-vault-name].vault.azure.net/
   AZURE_CLIENT_ID: [Application (client) ID]
   AZURE_TENANT_ID: [Directory (tenant) ID]
   AZURE_CLIENT_SECRET: [Client secret value]
   CERTIFICATE_NAME: nst-code-signing-cert
   ```

## Verification

1. The GitHub Actions workflow will automatically use these credentials
2. The first build after setup will verify if everything is working
3. You can monitor the build in the Actions tab of your repository

## Troubleshooting

If you encounter issues:
1. Check if all secrets are correctly set in GitHub
2. Verify App Registration has correct permissions in Key Vault
3. Ensure certificate is valid and properly imported
4. Check Azure Key Vault logs for any access issues

## Security Notes

1. Keep your client secret secure and never share it
2. Rotate the client secret periodically
3. Monitor Key Vault access logs for unusual activity
4. Consider using managed identities for production environments
