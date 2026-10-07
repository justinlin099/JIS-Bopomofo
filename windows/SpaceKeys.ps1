# Native Windows scan-code mapping; no DLL, hooks or resident process.
[CmdletBinding()]
param([ValidateSet('Install','Restore')][string]$Action='Install')
$ErrorActionPreference='Stop'
if(![Environment]::Is64BitProcess){throw 'Use 64-bit PowerShell'}
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
function Convert-ToSpaceMap([byte[]]$before){
 $entries=New-Object 'Collections.Generic.List[uint32]'
 if($before.Length){
  if($before.Length -lt 16 -or [BitConverter]::ToUInt64($before,0) -ne 0){throw 'Unsupported existing scan-code map header'}
  $count=[BitConverter]::ToUInt32($before,8)
  if($count -lt 1 -or $count -gt 4096 -or $before.Length -ne 12+4*$count -or [BitConverter]::ToUInt32($before,$before.Length-4) -ne 0){throw 'Invalid existing scan-code map length/terminator'}
  $seen=@{}
  for($i=0;$i -lt $count-1;$i++){
   $entry=[BitConverter]::ToUInt32($before,12+4*$i);$source=$entry -shr 16
   if(!$source -or $seen.ContainsKey($source)){throw 'Duplicate or invalid existing source scan code'}
   $seen[$source]=$true
   if($source -notin @(0x79,0x7b)){$entries.Add($entry)}
  }
 }
 $entries.Add([uint32]0x00790039);$entries.Add([uint32]0x007b0039)
 $result=New-Object byte[] (16+4*$entries.Count)
 [BitConverter]::GetBytes([uint32]($entries.Count+1)).CopyTo($result,8)
 for($i=0;$i -lt $entries.Count;$i++){[BitConverter]::GetBytes($entries[$i]).CopyTo($result,12+4*$i)}
 return ,$result
}
$folder=Join-Path $env:ProgramData 'Fujitsu-JIS-SpaceKeys'
$file=Join-Path $folder 'state.json'
New-Item -ItemType Directory -Path $folder -Force|Out-Null
if((Get-Item -LiteralPath $folder).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Reparse-point state folder is not supported'}
$acl=New-Object Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true,$false)
$acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))
foreach($sid in @('S-1-5-18','S-1-5-32-544','S-1-5-32-545')){
 $rights=if($sid -eq 'S-1-5-32-545'){'ReadAndExecute'}else{'FullControl'}
 $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier($sid)),$rights,'ContainerInherit,ObjectInherit','None','Allow')))
}
Set-Acl -LiteralPath $folder -AclObject $acl
function Save-State {
 $temp=Join-Path $folder ([Guid]::NewGuid().ToString('N')+'.tmp')
 [IO.File]::WriteAllText($temp,($script:state|ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
 if(Test-Path -LiteralPath $file){[IO.File]::Replace($temp,$file,(Join-Path $folder ('previous-'+[Guid]::NewGuid().ToString('N')+'.json')))}else{[IO.File]::Move($temp,$file)}
}
$key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Keyboard Layout',$true)
try{
 if(!$key){throw 'Keyboard Layout registry key is missing'}
 $present=$key.GetValueNames() -contains 'Scancode Map'
 if($present -and $key.GetValueKind('Scancode Map') -ne [Microsoft.Win32.RegistryValueKind]::Binary){throw 'Existing mapping is not REG_BINARY'}
 [byte[]]$before=@()
 if($present){$before=[byte[]]$key.GetValue('Scancode Map')}
 $encoded=[Convert]::ToBase64String($before)
 $old=if(Test-Path -LiteralPath $file){Get-Content -LiteralPath $file -Raw -Encoding UTF8|ConvertFrom-Json}else{$null}
 if($Action -eq 'Restore'){
  if(!$old -or $old.Format -ne 1){throw 'No supported backup exists'}
  if($encoded -notin @($old.Before,$old.After)){throw 'Mapping changed after installation; refusing to overwrite it'}
  if($old.WasPresent){$key.SetValue('Scancode Map',[Convert]::FromBase64String($old.Before),[Microsoft.Win32.RegistryValueKind]::Binary)}else{$key.DeleteValue('Scancode Map',$false)}
  $script:state=$old;$state.Status='Restored';Save-State
 }else{
  if($old -and $old.Status -notin @('Restored','RolledBack')){
   if($old.Status -eq 'Installed' -and $encoded -eq $old.After){[pscustomobject]@{Status='AlreadyInstalled';RestartRequired=$true};return}
   throw 'Restore the preceding transaction first'
  }
  [byte[]]$after=Convert-ToSpaceMap $before
  $script:state=[ordered]@{Format=1;CreatedAt=(Get-Date -Format o);Status='Prepared';WasPresent=$present;Before=$encoded;After=[Convert]::ToBase64String($after)}
  Save-State
  try{
   $key.SetValue('Scancode Map',$after,[Microsoft.Win32.RegistryValueKind]::Binary)
   if([Convert]::ToBase64String($key.GetValue('Scancode Map')) -ne $state.After){throw 'Mapping readback failed'}
   $state.Status='Installed';Save-State
  }catch{
   if($present){$key.SetValue('Scancode Map',$before,[Microsoft.Win32.RegistryValueKind]::Binary)}else{$key.DeleteValue('Scancode Map',$false)}
   $state.Status='RolledBack';Save-State;throw
  }
 }
 [pscustomobject]@{Status=$state.Status;RestartRequired=$true;Backup=$file;ResidentProcessAdded=$false}
}finally{if($key){$key.Dispose()}}
