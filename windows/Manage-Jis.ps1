# Windows 10 exact-source installation transaction. No keyboard hooks or resident helper.
[CmdletBinding()]
param([ValidateSet('Install','Restore')][string]$Action='Install',[switch]$FailAfterRegistration)
$ErrorActionPreference='Stop'
if(![Environment]::Is64BitProcess){throw '64-bit PowerShell is required'}
$os=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
if($Action -eq 'Install' -and ([int]$os.CurrentMajorVersionNumber -ne 10 -or [int]$os.CurrentBuildNumber -notin @(19044,19045))){throw 'This candidate requires Windows 10 build19044 or19045'}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if(!(New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Administrator token required'}
if($Action -eq 'Install' -and ((Get-Process wusa -ErrorAction SilentlyContinue) -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'))){throw 'Finish Windows servicing and restart before installation'}
$coreSub='SOFTWARE\Classes\CLSID\{25ecf786-a925-4706-a269-eef5ad6899db}\InProcServer32'
$layoutSub='SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404'
$originalCore=Join-Path $env:SystemRoot 'System32\IME\IMETC\IMTCCORE.DLL'
$stateRoot=Join-Path $env:ProgramData 'Fujitsu-JIS-Core'
$installRoot=Join-Path $env:ProgramFiles 'Fujitsu-JIS-Core'
$stateFile=Join-Path $stateRoot 'install-state.json'
$sections=[Security.AccessControl.AccessControlSections]'Access,Owner,Group'
if(-not ('JisCoreRegistryV2' -as [type])){Add-Type -Path (Join-Path $PSScriptRoot 'JisCoreRegistry.cs')}
function Read-Setting($sub,$name){
 $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($sub)
 try{
  if(!$key){throw "Missing registry key: HKLM\$sub"}
  if($key.GetValueNames() -notcontains $name){throw "Missing registry value: HKLM\$sub [$name]"}
  $kind=$key.GetValueKind($name).ToString()
  if($kind -notin @('String','ExpandString')){throw "Unsupported registry kind $kind at HKLM\$sub [$name]"}
  [pscustomobject]@{Value=[string]$key.GetValue($name);Raw=[string]$key.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);Kind=$kind;Acl=$key.GetAccessControl($sections).GetSecurityDescriptorSddlForm($sections)}
 }finally{if($key){$key.Dispose()}}
}
function Secure-Folder($path){
 New-Item -ItemType Directory -Path $path -Force|Out-Null
 if((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Reparse-point installation folders are not supported'}
 $acl=New-Object Security.AccessControl.DirectorySecurity
 $acl.SetAccessRuleProtection($true,$false)
 $administrators=New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
 $acl.SetOwner($administrators)
 foreach($sid in @('S-1-5-18','S-1-5-32-544','S-1-5-32-545')){
  $rights=if($sid -eq 'S-1-5-32-545'){'ReadAndExecute'}else{'FullControl'}
  $rule=New-Object Security.AccessControl.FileSystemAccessRule((New-Object Security.Principal.SecurityIdentifier($sid)),$rights,'ContainerInherit,ObjectInherit','None','Allow')
  $acl.AddAccessRule($rule)
 }
 Set-Acl -LiteralPath $path -AclObject $acl
}
function Save-State {
 $temp=Join-Path $stateRoot ([Guid]::NewGuid().ToString('N')+'.tmp')
 try{
  [IO.File]::WriteAllText($temp,($script:state|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding($false)))
  if(Test-Path -LiteralPath $stateFile){
   $backup=Join-Path $stateRoot ('state-'+[Guid]::NewGuid().ToString('N')+'.bak.json')
   [IO.File]::Replace($temp,$stateFile,$backup)
  }else{[IO.File]::Move($temp,$stateFile)}
 }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force}}
}
function Restore-Settings {
 $core=Read-Setting $coreSub ''
 $layout=Read-Setting $layoutSub 'Layout File'
 $oldRaw=if($script:state.Format -eq 1){$script:state.OldCore}else{$script:state.OldCoreRaw}
 $oldKind=if($script:state.Format -eq 1){'String'}else{$script:state.OldCoreKind}
 if($oldKind -notin @('String','ExpandString')){throw 'Unsupported original registry kind in backup'}
 $expanded=if($oldKind -eq 'ExpandString'){[Environment]::ExpandEnvironmentVariables($oldRaw)}else{$oldRaw}
 if($expanded -ine $originalCore){throw 'Original raw registry value does not resolve to the Microsoft core'}
 $alreadyOriginal=($core.Raw -ceq $oldRaw -and $core.Kind -eq $oldKind)
 $isInstalled=($core.Raw -ceq $script:state.NewCore -and $core.Kind -eq 'String')
 if(!$alreadyOriginal -and !$isInstalled){throw 'Settings changed outside this transaction; refusing to overwrite them'}
 if(!$alreadyOriginal){[JisCoreRegistryV2]::Set($core.Raw,$core.Kind,$oldRaw,$oldKind)}
 $afterCore=Read-Setting $coreSub '';$afterLayout=Read-Setting $layoutSub 'Layout File'
 if($afterCore.Raw -cne $oldRaw -or $afterCore.Kind -ne $oldKind -or $afterCore.Acl -ne $script:state.CoreAcl -or $afterLayout.Acl -ne $script:state.LayoutAcl){throw 'Restoration raw value, kind or ACL check failed'}
}
if($Action -eq 'Restore'){
 if(!(Test-Path -LiteralPath $stateFile)){throw 'No installation transaction exists'}
 $script:state=Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8|ConvertFrom-Json
 if($state.Format -notin @(1,2) -or $state.OldCore -ine $originalCore){throw 'Unsupported restoration record'}
 Restore-Settings
 $state.Status='Restored';Save-State
 [pscustomobject]@{Status=$state.Status;RestartRequired=$true;Core=(Read-Setting $coreSub '').Value;Layout=(Read-Setting $layoutSub 'Layout File').Value;FilesRetained=$state.InstallDirectory}
 return
}
if(Test-Path -LiteralPath $stateFile){
 $previous=Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8|ConvertFrom-Json
 if($previous.Status -notin @('Restored','RolledBack')){throw 'Existing transaction must be restored before a new installation'}
}
$coreBefore=Read-Setting $coreSub '';$layoutBefore=Read-Setting $layoutSub 'Layout File'
if($coreBefore.Value -ine $originalCore){throw 'Start from original Microsoft component registration'}
if($layoutBefore.Value -ine 'KBD106.DLL'){throw 'This candidate requires the existing working KBD106 configuration'}
$sourceHash=(Get-FileHash -LiteralPath $originalCore).Hash.ToLowerInvariant()
if($sourceHash -ne '9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628'){throw 'Unsupported Microsoft core; no settings changed'}
$recipeDoc=Get-Content (Join-Path $PSScriptRoot 'table7-build-recipes.json') -Raw -Encoding UTF8|ConvertFrom-Json
$recipe=@($recipeDoc.recipes|Where-Object {$_.sourceSHA256 -eq $sourceHash -and $_.variant -in @('lab64','5856-64','5794-64')})
if($recipe.Count -ne 1){throw 'Unsupported current Microsoft core; no installation changes made'}
$router=Join-Path $PSScriptRoot 'JisCoreRouter64.dll'
if((Get-FileHash -LiteralPath $router).Hash -ne '042cb9fe0f4d6d510d17444730614e3dc16c3fb7414a18e12c7da13ac321199b'){throw 'Unexpected tested router build'}
if((Get-AuthenticodeSignature -LiteralPath $originalCore).Status -ne 'Valid' -or (Get-AuthenticodeSignature -LiteralPath (Join-Path $env:SystemRoot 'System32\KBD106.DLL')).Status -ne 'Valid'){throw 'Expected signed original Microsoft components'}
Secure-Folder $stateRoot;Secure-Folder $installRoot
if(Test-Path -LiteralPath $stateFile){Copy-Item -LiteralPath $stateFile -Destination (Join-Path $stateRoot ('previous-'+[Guid]::NewGuid().ToString('N')+'.json'))}
$generation=Join-Path $installRoot ([Guid]::NewGuid().ToString('N'))
Secure-Folder $generation
$copyResult=& (Join-Path $PSScriptRoot 'Build-Table7-Copy.ps1') -SourceDll $originalCore -OutputDirectory $generation
$newCore=Join-Path $generation 'JisCoreRouter64.dll'
Copy-Item -LiteralPath $router -Destination $newCore
if((Get-FileHash -LiteralPath $newCore).Hash -ne (Get-FileHash -LiteralPath $router).Hash){throw 'Router copy verification failed'}
$script:state=[ordered]@{Format=2;CreatedAt=(Get-Date -Format o);Status='Prepared';OldCore=$coreBefore.Value;OldCoreRaw=$coreBefore.Raw;OldCoreKind=$coreBefore.Kind;OldLayout=$layoutBefore.Value;OldLayoutRaw=$layoutBefore.Raw;OldLayoutKind=$layoutBefore.Kind;NewCore=$newCore;CoreAcl=$coreBefore.Acl;LayoutAcl=$layoutBefore.Acl;SourceSHA256=$sourceHash;PatchSHA256=$copyResult.OutputSHA256;InstallDirectory=$generation;Error=$null}
Save-State
try{
 [JisCoreRegistryV2]::Set($coreBefore.Raw,$coreBefore.Kind,$newCore,'String')
 $state.Status='CoreWritten';Save-State
 if($FailAfterRegistration){throw 'Injected test failure after core registration'}
 $afterCore=Read-Setting $coreSub '';$afterLayout=Read-Setting $layoutSub 'Layout File'
 if($afterCore.Raw -cne $newCore -or $afterCore.Kind -ne 'String' -or $afterLayout.Raw -cne $layoutBefore.Raw -or $afterLayout.Kind -ne $layoutBefore.Kind -or $afterCore.Acl -ne $coreBefore.Acl -or $afterLayout.Acl -ne $layoutBefore.Acl -or (Get-FileHash -LiteralPath $originalCore).Hash -ine $sourceHash){throw 'Install readback or unchanged-original check failed'}
 $state.Status='Installed';Save-State
 [pscustomobject]@{Status=$state.Status;RestartRequired=$true;Core=$newCore;Layout=$afterLayout.Value;OriginalUnchanged=$true;RegistryAclUnchanged=$true;ResidentHelperAdded=$false}
}catch{
 $failure=$_.Exception.Message
 try{Restore-Settings;$state.Status='RolledBack'}catch{$state.Status='RollbackNeedsAttention';$failure+='; rollback: '+$_.Exception.Message}
 $state.Error=$failure;Save-State;throw $failure
}
