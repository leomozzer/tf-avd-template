$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=SLP2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
Get-ChildItem -Path "Cert:\CurrentUser\My"

$cert = Get-ChildItem -Path "Cert:\CurrentUser\My\B1C79D177D465E76FF74243F7553EA4837FD137B"
New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=SLP2SClientCert" -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(1) `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")