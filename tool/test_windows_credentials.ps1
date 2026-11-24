# On a disposable hosted runner, test the actual Flutter channel first. Give
# the second standard user only one synthetic ciphertext and its known context.
param([switch] $OtherUser, [string] $Record, [string] $WriterSid)
$ErrorActionPreference = 'Stop'

function Test-UserScope([byte[]] $envelope, [bool] $deny) {
    Add-Type -AssemblyName System.Security
    $scope = [Security.Cryptography.DataProtectionScope]::CurrentUser
    $entropy = [Text.Encoding]::UTF8.GetBytes("app.dourstuff/credential-record/v1`0X")
    $control = [byte[]] (1, 2, 3)
    $own = [Security.Cryptography.ProtectedData]::Protect($control, $entropy, $scope)
    $opened = [Security.Cryptography.ProtectedData]::Unprotect($own, $entropy, $scope)
    if ([Convert]::ToBase64String($opened) -ne 'AQID') { throw 'DPAPI control failed' }
    # The first 32 bytes authenticate the entire DPAPI blob in the Dart adapter.
    $blob = [byte[]] $envelope[32..($envelope.Length - 1)]
    try {
        $plain = [Security.Cryptography.ProtectedData]::Unprotect($blob, $entropy, $scope)
    } catch [Security.Cryptography.CryptographicException] {
        if ($deny) { return }
        throw 'Writer could not open the record'
    }
    if ($deny -or [Text.Encoding]::UTF8.GetString($plain, 32, $plain.Length - 32) -ne 'synthetic-X') {
        throw 'Unexpected credential access'
    }
}

$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($OtherUser) {
    if (!$WriterSid -or $sid -eq $WriterSid) { throw 'Expected another logon' }
    Test-UserScope ([IO.File]::ReadAllBytes($Record)) $true
    exit 0
}
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted') {
    throw 'Run the account-creation fixture only on a disposable GitHub-hosted runner'
}
$fixture = New-Item -ItemType Directory -Path (Join-Path $env:RUNNER_TEMP ([guid]::NewGuid()))
$exe = Resolve-Path build/windows/x64/runner/Release/dourstuff.exe
foreach ($phase in 'seed','verify','interrupt','verify','interrupt-refresh','recover-refresh') {
    Set-Content -LiteralPath (Join-Path $fixture mode) -NoNewline -Value $phase
    $process = Start-Process $exe -ArgumentList ('"{0}"' -f $fixture.FullName) -PassThru -WindowStyle Hidden
    if (!$process.WaitForExit(60000) -or $process.ExitCode -ne 0) { throw "Failed $phase" }
    if (!$phase.StartsWith('interrupt') -and (Get-Content (Join-Path $fixture result)) -ne "passed $phase") {
        throw "Incomplete $phase"
    }
}
$recordPath = Join-Path $fixture 'x.record'
Test-UserScope ([IO.File]::ReadAllBytes($recordPath)) $false
$shared = New-Item -ItemType Directory -Path (Join-Path $env:ProgramData ([guid]::NewGuid()))
Copy-Item -LiteralPath $recordPath -Destination $shared
Copy-Item -LiteralPath $PSCommandPath -Destination $shared
$name = 'ds' + [guid]::NewGuid().ToString('N').Substring(0, 12)
$password = ConvertTo-SecureString ([guid]::NewGuid().ToString('N') + 'aA1!') -AsPlainText -Force
$user = New-LocalUser -Name $name -Password $password
try {
    icacls $shared.FullName /grant "*$($user.SID.Value):(OI)(CI)RX" | Out-Null
    if ($LASTEXITCODE) { throw 'Could not grant synthetic fixture read access' }
    $credential = [pscredential]::new("$env:COMPUTERNAME\$name", $password)
    $script = Join-Path $shared 'test_windows_credentials.ps1'
    $recordPath = Join-Path $shared 'x.record'
    $arguments = "-NoProfile -NonInteractive -File `"$script`" -OtherUser -WriterSid $sid -Record `"$recordPath`""
    $process = Start-Process powershell.exe -Credential $credential -LoadUserProfile -WorkingDirectory $shared.FullName -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (!$process.WaitForExit(60000) -or $process.ExitCode -ne 0) { throw 'Second-user DPAPI check failed' }
} finally {
    Remove-LocalUser -SID $user.SID
}
