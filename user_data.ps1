<powershell>
net user /add AdminWeb V3gbk24f
net localgroup administrators AdminWeb /add


winrm quickconfig -q
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
$valueset = @{
    Hostname = $env:COMPUTERNAME
    CertificateThumbprint = $cert.Thumbprint
}
$selectorset = @{
    Transport = "HTTPS"
    Address = "*"
}
New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset -ValueSet $valueset

New-NetFirewallRule -DisplayName 'WinRM' -Profile @('Domain', 'Private', 'Public') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5985', '5986')


net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
