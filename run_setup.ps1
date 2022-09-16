[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]$InputPassword
)

Function InstallChocolatey{
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

Function SetupCygwinWithAnsible{
    choco install -y cygwin "--no-desktop --quiet-mode --wait"
    choco install -y cyg-get 
    cyg-get ansible

    $SystemPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $SystemPath += ";C:\tools\cygwin\bin"
    [System.Environment]::SetEnvironmentVariable("Path", $SystemPath, "User")
    refreshenv

    $Options = "-l -c `"ansible --version`" "
    Start-Process  "C:\tools\cygwin\bin\bash" -ArgumentList $Options -Wait -NoNewWindow
}

Function SetupWinRMForAnsible{
    $SetupScriptForAnsible = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
    $File = "$env:temp\ConfigureRemotingForAnsible.ps1"
    (New-Object -TypeName System.Net.WebClient).DownloadFile($SetupScriptForAnsible, $File)
    powershell -ExecutionPolicy RemoteSigned $File -ForceNewSSLCert -SkipNetworkProfileCheck -Verbose
}

Function CheckWinRMConnectivity{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$UserName,

        [Parameter(Mandatory)]
        [String]$UserPassword,

        [Parameter(Mandatory)]
        [String]$TargetHost
    )
    $Password = ConvertTo-SecureString -String $UserPassword -AsPlainText -Force 
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password
    $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck 
    Invoke-Command -ComputerName $TargetHost -UseSSL -ScriptBlock { ipconfig } -Credential $Cred -SessionOption $SessionOption
}

Function RunCommand{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$FileName,

        [String]$Arguments
    )

    $ProcessInfo = New-object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.CreateNoWindow = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.FileName = $FileName
    $ProcessInfo.Arguments = $Arguments

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null
    $Process.WaitForExit()
    
    return $Process.StandardOutput.ReadToEnd()
}

Function GetCygPath{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$WinPath
    )
    $Options = "-l -c `"cygpath -u ${WinPath}`""
    return RunCommand "C:\tools\cygwin\bin\bash" $Options | % { $_ -replace "`n", "" }
}

Function RunPlaybook{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$InventoryFile,

        [Parameter(Mandatory)]
        [String]$PlaybookFile
    )
    $CygInventoryFile = GetCygPath ${InventoryFile}
    $CygPlaybookFile = GetCygPath ${PlaybookFile}

    $Options = "-l -c `"ansible-playbook -i ${CygInventoryFile} ${CygPlaybookFile} `" "
    echo $Options
    Start-Process  "C:\tools\cygwin\bin\bash" -ArgumentList $Options -Wait -NoNewWindow
}

Function CreateInventoryFile{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$UserName,

        [Parameter(Mandatory)]
        [String]$Password,

        [Parameter(Mandatory)]
        [String]$TargetHost,
        
        [Parameter(Mandatory)]
        [String]$FilePath
    )
    $Cotents = @"
[winrm_local]
${TargetHost}

[winrm_local:vars]
ansible_user=${UserName}
ansible_password=${Password}
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
"@
    Set-Content -Path $FilePath -Value $Cotents -Encoding Ascii 
}

$UserName = "WDAGUtilityAccount"
$Password = $InputPassword 
net user $UserName $Password

InstallChocolatey
SetupCygwinWithAnsible
SetupWinRMForAnsible

$TargetHost = "127.0.0.1"
CheckWinRMConnectivity $UserName $Password $TargetHost

$InventoryFile = $PSScriptRoot + '\hosts'
$PlaybookFile = $PSScriptRoot + '\dev_playbook.yml'
$InventoryFile = $InventoryFile.Replace("\", "\\\\")
$PlaybookFile = $PlaybookFile.Replace("\", "\\\\")

CreateInventoryFile $UserName $Password $TargetHost $InventoryFile
RunPlaybook $InventoryFile $PlaybookFile
