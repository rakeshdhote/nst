# Setting up macOS App Notarization

This guide explains how to set up code signing and notarization for your macOS application. Apple requires apps to be both signed and notarized for distribution outside the App Store.

## Prerequisites

1. Apple Developer Account
   - Enroll in the [Apple Developer Program](https://developer.apple.com/programs/)
   - Individual ($99/year) or Organization account

2. Xcode Command Line Tools
   ```bash
   xcode-select --install
   ```

3. macOS machine for initial setup

## Step 1: Create Apple Developer Certificate

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)

2. Click [+] to create a new certificate:
   - Select "Developer ID Application"
   - Follow the wizard to create a Certificate Signing Request (CSR)
   - Download the certificate

3. Double-click the downloaded certificate to add it to Keychain

## Step 2: Create App-Specific Password

1. Go to [Apple ID Account](https://appleid.apple.com/)
2. Sign in → Security → App-Specific Passwords
3. Click [+] Generate Password
4. Name it (e.g., "NST App Notarization")
5. Save the generated password securely

## Step 3: Set up Notarization Credentials

1. Create a keychain profile for notarization:
   ```bash
   xcrun notarytool store-credentials "notarytool-profile" \
     --apple-id "your.email@example.com" \
     --team-id "YOUR_TEAM_ID" \
     --password "APP_SPECIFIC_PASSWORD"
   ```

2. Test the credentials:
   ```bash
   xcrun notarytool info --profile "notarytool-profile"
   ```

## Step 4: Configure GitHub Secrets

Add these secrets to your GitHub repository:
1. Go to Settings → Secrets and variables → Actions
2. Add new secrets:
   ```
   APPLE_CERTIFICATE: Base64 encoded Developer ID certificate
   APPLE_CERTIFICATE_PASSWORD: Certificate password
   APPLE_ID: Your Apple ID email
   APPLE_TEAM_ID: Your Team ID
   APPLE_PASSWORD: App-specific password
   ```

To encode your certificate:
```bash
base64 -i /path/to/certificate.p12 | pbcopy
```

## Step 5: Update Tauri Configuration

1. Edit `tauri.conf.json`:
```json
{
  "tauri": {
    "bundle": {
      "macOS": {
        "frameworks": [],
        "minimumSystemVersion": "10.13",
        "signingIdentity": "Developer ID Application: Your Name (TEAM_ID)",
        "entitlements": "entitlements.plist",
        "providerShortName": "TEAM_ID"
      }
    }
  }
}
```

2. Create `entitlements.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

## Step 6: Manual Notarization Process

If you need to notarize manually:

1. Sign the app:
```bash
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements entitlements.plist \
  "path/to/Your.app"
```

2. Create ZIP for notarization:
```bash
ditto -c -k --keepParent "path/to/Your.app" "Your.zip"
```

3. Submit for notarization:
```bash
xcrun notarytool submit "Your.zip" \
  --profile "notarytool-profile" \
  --wait
```

4. Verify notarization:
```bash
xcrun notarytool info --profile "notarytool-profile" [submission-id]
```

5. Staple the ticket:
```bash
xcrun stapler staple "path/to/Your.app"
```

## Troubleshooting

### Common Issues

1. Certificate Not Found:
   ```bash
   security find-identity -v -p codesigning
   ```
   Verify your certificate is listed

2. Notarization Failed:
   ```bash
   xcrun notarytool log [submission-id] --profile "notarytool-profile"
   ```
   Check detailed error logs

3. Stapling Failed:
   - Ensure app is properly signed
   - Check internet connection
   - Verify notarization completed successfully

### Verification Commands

1. Check signature:
```bash
codesign -vv --deep --strict "path/to/Your.app"
```

2. Verify notarization:
```bash
spctl --assess -vv "path/to/Your.app"
```

## GitHub Actions Integration

Your workflow should include these steps:

1. Import certificate:
```yaml
- name: Install Apple Certificate
  run: |
    echo "${{ secrets.APPLE_CERTIFICATE }}" | base64 --decode > certificate.p12
    security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
    security import certificate.p12 -k build.keychain -P "${{ secrets.APPLE_CERTIFICATE_PASSWORD }}" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
```

2. Build and sign:
```yaml
- name: Build and Sign
  env:
    APPLE_SIGNING_IDENTITY: ${{ secrets.APPLE_SIGNING_IDENTITY }}
  run: |
    pnpm tauri build
```

3. Notarize:
```yaml
- name: Notarize
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
    APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
  run: |
    xcrun notarytool submit "path/to/Your.app" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_PASSWORD" \
      --wait
```

## Best Practices

1. Security:
   - Keep certificates and passwords secure
   - Use app-specific passwords
   - Regularly rotate passwords
   - Use secure keychain handling

2. Build Process:
   - Automate signing and notarization
   - Include verification steps
   - Handle errors gracefully
   - Log important steps

3. Testing:
   - Test on different macOS versions
   - Verify Gatekeeper acceptance
   - Check for hardened runtime issues
   - Test all app functionality post-signing

## Additional Resources

- [Apple's Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/documentation/security/code_signing_services)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Troubleshooting Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues)
