$UserCredential = Get-Credential
$so = New-PsSessionOption -SkipCACheck -SkipCNCheck
$session = New-PSSession -ComputerName 18.130.160.201 -Credential $UserCredential -UseSSL -SessionOption $so
Invoke-Command -Session $session {Install-WindowsFeature -name Web-Server -IncludeManagementTools}
Invoke-Command -Session $session {net stop WAS /y}
Invoke-Command -Session $session {Remove-Item -path C:\inetpub\wwwroot\*}
Copy-Item –Path index.html –Destination 'C:\inetpub\wwwroot' -recurse -Force –ToSession $session
Invoke-Command -Session $session {net start W3SVC}