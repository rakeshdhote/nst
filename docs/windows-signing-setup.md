# Setting up Windows Code Signing Certificate

This guide explains how to generate a self-signed certificate for code signing Windows applications and set it up with GitHub Actions.

## Prerequisites

- Windows 10/11 with PowerShell
- Administrator access
- Git repository with GitHub Actions

## Method 1: Using the Provided Script

We provide a PowerShell script that automates the certificate generation process.

1. Open PowerShell as Administrator

2. Navigate to your project directory:
   ```powershell
   cd path\to\your\project
   ```

3. Run the certificate generation script:
   ```powershell
   .\scripts\generate_cert.ps1 -CertPassword "YourStrongPassword"
   ```

   Optional parameters:
   - `-OrganizationName`: Your organization name (default: "NST Tech")
   - `-CountryCode`: Your country code (default: "US")
   - `-OutputDirectory`: Where to save certificates (default: ".\certificates")

4. The script will create:
   - `certificates/signing_cert.pfx`: The certificate file
   - `certificates/certificate_base64.txt`: Base64-encoded certificate for GitHub

## Method 2: Manual Generation

If you prefer to generate the certificate manually:

1. Open PowerShell as Administrator

2. Generate the certificate:
   ```powershell
   $cert = New-SelfSignedCertificate `
       -Type Custom `
       -Subject "CN=Your Company Name, O=Your Company Name, C=US" `
       -KeyUsage DigitalSignature `
       -FriendlyName "Your Company Signing Certificate" `
       -CertStoreLocation "Cert:\CurrentUser\My" `
       -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}false") `
       -NotAfter (Get-Date).AddYears(3)
   ```

3. Set a password and export to PFX:
   ```powershell
   $password = ConvertTo-SecureString -String "YourStrongPassword" -Force -AsPlainText
   $pfxPath = "signing_cert.pfx"
   $certPath = "Cert:\CurrentUser\My\$($cert.Thumbprint)"
   
   Export-PfxCertificate -Cert $certPath -FilePath $pfxPath -Password $password
   ```

4. Convert to Base64:
   ```powershell
   $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
   Set-Content -Path "certificate_base64.txt" -Value $base64
   ```

5. Clean up:
   ```powershell
   Remove-Item $certPath
   ```

## Setting up GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add two new secrets:
   - `WINDOWS_SIGN_CERT`: Copy and paste the entire contents of `certificate_base64.txt`
   - `WINDOWS_SIGN_CERT_PASSWORD`: Enter the password you used when creating the certificate

## Security Considerations

1. Certificate Storage:
   - Keep your PFX file secure
   - Don't commit certificates to source control
   - Add `certificates/` to your `.gitignore`

2. Password Security:
   - Use a strong password
   - Store the password securely
   - Don't share the password in plain text

3. Certificate Limitations:
   - Self-signed certificates will trigger Windows security warnings
   - For production apps, consider purchasing a certificate from a trusted CA

## Adding to .gitignore

Add these lines to your `.gitignore`:
```
# Code signing certificates
certificates/
*.pfx
certificate_base64.txt
```

## Troubleshooting

1. Certificate Not Found:
   - Ensure PowerShell is running as Administrator
   - Check certificate path in certificate store

2. Base64 Conversion Issues:
   - Verify the PFX file exists
   - Ensure no line breaks in base64 output

3. GitHub Actions Errors:
   - Verify secret names match the workflow
   - Check secret values are properly copied
   - Ensure password matches exactly

## Production Recommendations

For production applications:

1. Purchase a Code Signing Certificate:
   - DigiCert
   - Sectigo
   - GlobalSign
   - Other trusted Certificate Authorities

2. Benefits of Trusted Certificates:
   - No Windows security warnings
   - Better user trust
   - Professional appearance

3. Certificate Management:
   - Keep backups of your certificate
   - Track expiration dates
   - Plan for renewal

## Testing the Certificate

To verify your certificate works:

1. Build your application locally
2. Sign it with your certificate:
   ```powershell
   signtool sign /f signing_cert.pfx /p YourStrongPassword /fd sha256 /tr http://timestamp.digicert.com /td sha256 YourApp.exe
   ```
3. Check the signature:
   ```powershell
   signtool verify /pa YourApp.exe
   ```

## Additional Resources

- [Microsoft Docs: Code Signing](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [Windows Code Signing Best Practices](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/authenticode-signing-of-windows-applications)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides)
