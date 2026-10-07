[CmdletBinding()]
param([ValidateSet('Install','Restore','InstallSpaces','RestoreSpaces')][string]$Action='Install')
$ErrorActionPreference='Stop'
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Right-click the CMD file and choose Run as administrator'}
$log=Join-Path $PSScriptRoot ($Action+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log.txt')
Start-Transcript -LiteralPath $log|Out-Null
try{
 if($Action -eq 'InstallSpaces'){& (Join-Path $PSScriptRoot 'SpaceKeys.ps1') -Action Install}
 elseif($Action -eq 'RestoreSpaces'){& (Join-Path $PSScriptRoot 'SpaceKeys.ps1') -Action Restore}
 elseif($Action -eq 'Install'){
  & (Join-Path $PSScriptRoot 'Manage-Jis.ps1') -Action Install
  try{& (Join-Path $PSScriptRoot 'SpaceKeys.ps1') -Action Install}
  catch{
   $failure=$_.Exception.Message
   try{& (Join-Path $PSScriptRoot 'Manage-Jis.ps1') -Action Restore}catch{$failure+='; core rollback failed: '+$_.Exception.Message}
   throw $failure
  }
 }else{
  $failures=@()
  if(Test-Path (Join-Path $env:ProgramData 'Fujitsu-JIS-Core\install-state.json')){
   try{& (Join-Path $PSScriptRoot 'Manage-Jis.ps1') -Action Restore}catch{$failures+=('Core: '+$_.Exception.Message)}
  }
  if(Test-Path (Join-Path $env:ProgramData 'Fujitsu-JIS-SpaceKeys\state.json')){
   try{& (Join-Path $PSScriptRoot 'SpaceKeys.ps1') -Action Restore}catch{$failures+=('Space keys: '+$_.Exception.Message)}
  }
  if($failures.Count){throw ($failures -join '; ')}
 }
 Write-Host 'Completed. Save your work and RESTART Windows to apply the change.'
}finally{Stop-Transcript|Out-Null}
