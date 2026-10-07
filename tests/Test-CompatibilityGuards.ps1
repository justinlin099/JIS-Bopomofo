# SPDX-License-Identifier: GPL-3.0-or-later
# Execute only selected pure guard statements extracted from the shipped installer.
# No installer execution, registry access, module loading or OS impersonation.
$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot '../windows/Manage-Jis.ps1'
$tokens=$null;$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Installer parse failed'}
function Get-Guard([string]$message){
 $matches=@($ast.EndBlock.Statements | Where-Object {$_ -is [System.Management.Automation.Language.IfStatementAst] -and $_.Extent.Text.Contains($message)})
 if($matches.Count -ne 1){throw "Expected one top-level guard: $message"}
 $firstMutation=@($ast.EndBlock.Statements | Where-Object {$_.Extent.Text -eq 'Secure-Folder $stateRoot'})
 if($firstMutation.Count -ne 1 -or $matches[0].Extent.StartOffset -ge $firstMutation[0].Extent.StartOffset){throw 'Guard no longer precedes installation folder mutation'}
 [scriptblock]::Create($matches[0].Extent.Text)
}
$osGuard=Get-Guard 'This candidate requires Windows 10 build19044 or19045'
$hashGuard=Get-Guard 'Unsupported Microsoft core; no settings changed'
$layoutGuard=Get-Guard 'This candidate requires the existing working KBD106 configuration'
$coreGuard=Get-Guard 'Start from original Microsoft component registration'
$rows=New-Object 'Collections.Generic.List[object]'
function Check([string]$name,[scriptblock]$guard,[bool]$expectReject){
 $rejected=$false;$message=$null
 try{& $guard}catch{$rejected=$true;$message=$_.Exception.Message}
 $row=[pscustomobject]@{Name=$name;ExpectedReject=$expectReject;Rejected=$rejected;Passed=($rejected -eq $expectReject);Message=$message}
 $rows.Add($row)
 if(!$row.Passed){throw "Guard mismatch: $name"}
}
$Action='Install'
foreach($build in @(7601,9600,17763,18363,19041,19043,19044,19045,20348,22000,22621,22631,26100,26200)){
 $os=[pscustomobject]@{CurrentMajorVersionNumber=10;CurrentBuildNumber=$build}
 Check "Build-$build" $osGuard ($build -notin @(19044,19045))
}
$os=[pscustomobject]@{CurrentMajorVersionNumber=6;CurrentBuildNumber=19045}
Check 'Non-10-major' $osGuard $true
$Action='Restore';$os=[pscustomobject]@{CurrentMajorVersionNumber=10;CurrentBuildNumber=26100}
Check 'Restore-not-blocked-by-build-guard' $osGuard $false
$Action='Install'
foreach($hash in @('9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628','f476b20ee91bdf2e49b5c8bfdbc95cfa0bab7146cd52c98a65e71e6148bfd047',('0'*64))){
 $sourceHash=$hash
 Check ('Source-'+$hash.Substring(0,8)) $hashGuard ($hash -ne '9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628')
}
foreach($layout in @('KBD106.DLL','kbd106.dll','KBDUS.DLL','custom.dll')){
 $layoutBefore=[pscustomobject]@{Value=$layout}
 Check ('Layout-'+$layout) $layoutGuard ($layout -ine 'KBD106.DLL')
}
$originalCore='C:\Windows\System32\IME\IMETC\IMTCCORE.DLL'
foreach($value in @($originalCore,'C:\Example\OtherCore.dll')){
 $coreBefore=[pscustomobject]@{Value=$value}
 Check ('Core-original-'+($value -eq $originalCore)) $coreGuard ($value -ine $originalCore)
}
$report=[pscustomobject]@{TestType='Extracted pure installer guards; not OS integration tests';Cases=$rows.Count;AllPassed=(@($rows|Where-Object {!$_.Passed}).Count -eq 0);Results=@($rows.ToArray())}
$report|ConvertTo-Json -Depth 5|Set-Content (Join-Path $PSScriptRoot 'compatibility-guard-results.json') -Encoding UTF8
$report|Select-Object TestType,Cases,AllPassed
