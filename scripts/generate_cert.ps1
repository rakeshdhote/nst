param(
    [Parameter(Mandatory=$true)]
    [string]$CertPassword,
    [string]$OrganizationName = "NST Tech",
    [string]$CountryCode = "US",
    [string]$OutputDirectory = ".\certificates"
)

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$pfxPath = Join-Path $OutputDirectory "signing_cert.pfx"
$base64Path = Join-Path $OutputDirectory "certificate_base64.txt"

try {
    Write-Host "Generating self-signed certificate..."
    
    # Generate certificate
    $cert = New-SelfSignedCertificate `
        -Type Custom `
        -Subject "CN=$OrganizationName, O=$OrganizationName, C=$CountryCode" `
        -KeyUsage DigitalSignature `
        -FriendlyName "$OrganizationName Signing Certificate" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}false") `
        -NotAfter (Get-Date).AddYears(3)

    $password = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    $certPath = "Cert:\CurrentUser\My\$($cert.Thumbprint)"

    Write-Host "Exporting certificate to PFX..."
    Export-PfxCertificate -Cert $certPath -FilePath $pfxPath -Password $password

    Write-Host "Converting to Base64..."
    $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))
    Set-Content -Path $base64Path -Value $base64

    Write-Host "`nCertificate generated successfully!"
    Write-Host "PFX file: $pfxPath"
    Write-Host "Base64 certificate: $base64Path"
    Write-Host "`nNext steps:"
    Write-Host "1. Add the contents of $base64Path as a GitHub secret named 'WINDOWS_SIGN_CERT'"
    Write-Host "2. Add the certificate password as a GitHub secret named 'WINDOWS_SIGN_CERT_PASSWORD'"
    
    # Clean up certificate from store
    Remove-Item $certPath
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
