# Setting Up Signing Keys for Tauri Application

This guide explains how to set up code signing for your Tauri application across different platforms.

## Table of Contents
- [GitHub Secrets Setup](#github-secrets-setup)
- [Tauri Private Key Setup](#tauri-private-key-setup)
- [Windows Code Signing](#windows-code-signing)
- [macOS Code Signing](#macos-code-signing)
- [Environment Variables](#environment-variables)

## GitHub Secrets Setup

All sensitive keys and passwords should be stored as GitHub repository secrets. Go to your GitHub repository:

1. Navigate to `Settings` → `Secrets and variables` → `Actions`
2. Click on `New repository secret`
3. Add the following secrets:
   - `TAURI_PRIVATE_KEY`
   - `TAURI_KEY_PASSWORD`
   - `TAURI_SIGNING_PRIVATE_KEY`
   - `WINDOWS_SIGN_CERT_PASSWORD`
   - `GITHUB_TOKEN` (automatically provided by GitHub Actions)

## Tauri Private Key Setup

### Prerequisites

#### Linux (Ubuntu/Debian)
```bash
# Install system dependencies
sudo apt update
sudo apt install -y curl build-essential libssl-dev pkg-config openssl

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install Tauri CLI
cargo install tauri-cli
```

#### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install curl openssl pkg-config

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install Tauri CLI
cargo install tauri-cli
```

#### Windows
```powershell
# Install Chocolatey if not already installed (Run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install dependencies (Run as Administrator)
choco install rust-ms openssl pkgconfiglite

# Install Tauri CLI (in regular PowerShell)
cargo install tauri-cli
```

### Step 1: Generate Tauri Keys

#### Linux/macOS
```bash
# Create a directory for your keys
mkdir -p ~/.tauri/keys
cd ~/.tauri/keys

# Generate the keys
cargo tauri signer generate

# Save the output to files
cargo tauri signer generate | tee keys.txt
```

#### Windows (PowerShell)
```powershell
# Create directory for keys
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.tauri\keys"
Set-Location "$env:USERPROFILE\.tauri\keys"

# Generate and save keys
cargo tauri signer generate | Tee-Object -FilePath keys.txt
```

### Step 2: Set Up TAURI_PRIVATE_KEY

#### Linux/macOS
```bash
# Extract private key from output
grep "Private Key:" keys.txt | cut -d' ' -f3- > private_key.txt

# Convert to base64 if needed
base64 -w 0 private_key.txt > private_key.b64
```

#### Windows
```powershell
# Extract private key from output
$privateKey = (Get-Content keys.txt | Select-String "Private Key:").Line.Split(": ")[1]
$privateKey | Out-File private_key.txt

# Convert to base64 if needed
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content private_key.txt))) | Out-File private_key.b64
```

### Step 3: Set Up TAURI_KEY_PASSWORD

#### Linux/macOS
```bash
# Extract key password from output

grep "Key Password:" keys.txt | cut -d' ' -f3- > key_password.txt // Not correct. manually copy paste the key and proceed with next steps
```

#### Windows
```powershell
# Extract key password from output
$keyPassword = (Get-Content keys.txt | Select-String "Key Password:").Line.Split(": ")[1]
$keyPassword | Out-File key_password.txt
```

### Step 4: Set Up TAURI_SIGNING_PRIVATE_KEY

#### Linux/macOS
```bash
# Generate certificate and private key
openssl req -x509 -newkey rsa:4096 -keyout private.key -out cert.pem -days 36500 -nodes \
    -subj "/CN=NSR Tech/O=NSR Tech/C=CA"

# Convert to PKCS12 format
openssl pkcs12 -export -out certificate.p12 -inkey private.key -in cert.pem \
    -name "Developer ID Application" -passout pass:DEFAULT

# Convert to base64
base64 -w 0 certificate.p12 > signing_key.b64
```

#### Windows
```powershell
# Generate certificate and private key
$cert = New-SelfSignedCertificate -Type Custom -Subject "CN=Your Company" `
    -KeyUsage DigitalSignature -FriendlyName "Your Company Certificate" `
    -CertStoreLocation "Cert:\CurrentUser\My"

# Export certificate with private key
$password = ConvertTo-SecureString -String "temppass" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" `
    -FilePath certificate.pfx -Password $password

# Convert to base64
$bytes = [System.IO.File]::ReadAllBytes("certificate.pfx")
[Convert]::ToBase64String($bytes) | Out-File signing_key.b64
```

### Step 5: Add Keys to GitHub Secrets

1. Go to your GitHub repository → Settings → Secrets → Actions → New repository secret

2. Add the following secrets:
   ```
   TAURI_PRIVATE_KEY: [Content of private_key.b64]
   TAURI_KEY_PASSWORD: [Content of key_password.txt]
   TAURI_SIGNING_PRIVATE_KEY: [Content of signing_key.b64]
   ```

### Step 6: Update tauri.conf.json
```json
{
  "tauri": {
    "bundle": {
      "signingIdentity": null,
      "publisher": "Your Company Name",
      "security": {
        "csp": null
      }
    },
    "security": {
      "signature": {
        "publicKey": "YOUR_PUBLIC_KEY_HERE"
      }
    }
  }
}
```

## Verification Steps

### Linux/macOS
```bash
# Verify keys
cargo tauri signer verify

# Test signing
echo "test" > test.txt
cargo tauri signer sign test.txt

# Test build
cargo tauri build
```

### Windows
```powershell
# Verify keys
cargo tauri signer verify

# Test signing
"test" | Out-File test.txt
cargo tauri signer sign test.txt

# Test build
cargo tauri build
```

## Important Security Notes

1. **Clean Up Sensitive Files:**
   ```bash
   # Linux/macOS
   rm keys.txt private_key.txt key_password.txt private.key cert.pem certificate.p12

   # Windows
   Remove-Item keys.txt, private_key.txt, key_password.txt, certificate.pfx
   ```

2. **Key Storage:**
   - Store base64 encoded keys in a secure password manager
   - Keep offline backup in a secure location
   - Never commit keys to version control

3. **Key Rotation:**
   - Rotate keys every 12 months
   - Immediately rotate if compromised
   - Document rotation procedures

4. **Access Control:**
   - Limit GitHub Secrets access
   - Use different keys for development/production
   - Regular security audits

## Windows Code Signing

1. Generate a certificate:
```powershell
New-SelfSignedCertificate -Type Custom -Subject "CN=YourCompany, O=YourCompany, C=US" -KeyUsage DigitalSignature -FriendlyName "Your Company Certificate" -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
```

2. Export the certificate:
```powershell
$password = ConvertTo-SecureString -String "YourPassword" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\<Certificate-Thumbprint>" -FilePath certificate.pfx -Password $password
```

3. Convert the certificate to base64:
```bash
base64 -w 0 certificate.pfx > certificate.b64
```

4. Store in GitHub Secrets:
   - Certificate content as `WINDOWS_CERTIFICATE`
   - Password as `WINDOWS_SIGN_CERT_PASSWORD`

## macOS Code Signing

1. Generate a signing certificate in Keychain Access or Apple Developer Portal
2. Export the certificate and private key as .p12 file
3. Convert to base64:
```bash
base64 -w 0 certificate.p12 > certificate.b64
```

4. Store in GitHub Secrets as `TAURI_SIGNING_PRIVATE_KEY`

## Environment Variables

In your GitHub Actions workflow, the following variables are used:

```yaml
env:
  ENABLE_CODE_SIGNING: true  # Set to false to disable code signing
  APPLE_CERTIFICATE_PATH: ${{ runner.temp }}/apple_certificate.p12
  APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
  APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
  APPLE_SIGNING_IDENTITY: ${{ secrets.APPLE_SIGNING_IDENTITY }}
  APPLE_ID: ${{ secrets.APPLE_ID }}
  APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
  APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
  TAURI_PRIVATE_KEY: ${{ secrets.TAURI_PRIVATE_KEY }}
  TAURI_KEY_PASSWORD: ${{ secrets.TAURI_KEY_PASSWORD }}
  TAURI_SIGNING_PRIVATE_KEY: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}
  WINDOWS_SIGN_CERT_PASSWORD: ${{ secrets.WINDOWS_SIGN_CERT_PASSWORD }}
```

## Security Notes

1. Never commit private keys or certificates to your repository
2. Always use GitHub Secrets for sensitive data
3. Rotate keys and certificates periodically
4. Use strong passwords for your certificates
5. Limit access to your signing keys to authorized personnel only

## Verification

To verify your setup:

1. Check if signing is enabled:
```bash
cargo tauri signer verify
```

2. Test build with signing:
```bash
cargo tauri build --target x86_64-pc-windows-msvc  # For Windows
cargo tauri build --target x86_64-apple-darwin     # For macOS
cargo tauri build --target x86_64-unknown-linux-gnu # For Linux
```

## Troubleshooting

If you encounter signing issues:

1. Verify all secrets are properly set in GitHub
2. Check the certificate expiration dates
3. Ensure the signing identity matches your certificate
4. Verify the password for certificates is correct
5. Check the GitHub Actions logs for specific error messages
