# Read only: records the registry value kinds omitted by the earlier report.
$ErrorActionPreference='Stop'
if(![Environment]::Is64BitProcess){throw 'Please use the included Check.cmd (64-bit PowerShell).'}
function Read-Value([string]$view,[string]$sub,[string]$name){
 $root=$null;$key=$null
 $row=[ordered]@{View=$view;Key=$sub;Name=$name;KeyExists=$false;ValueExists=$false;Kind=$null;RawValue=$null;ExpandedValue=$null;Acl=$null;Error=$null}
 try{
  $root=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::$view)
  $key=$root.OpenSubKey($sub)
  $row.KeyExists=($null -ne $key)
  if($key){
   $row.ValueExists=($key.GetValueNames() -contains $name)
   if($row.ValueExists){
    $row.Kind=$key.GetValueKind($name).ToString()
    $row.RawValue=$key.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $row.ExpandedValue=$key.GetValue($name)
   }
   $sections=[Security.AccessControl.AccessControlSections]'Access,Owner,Group'
   $row.Acl=$key.GetAccessControl($sections).GetSecurityDescriptorSddlForm($sections)
  }
 }catch{$row.Error=$_.Exception.Message}
 finally{if($key){$key.Dispose()};if($root){$root.Dispose()}}
 [pscustomobject]$row
}
$core='SOFTWARE\Classes\CLSID\{25ecf786-a925-4706-a269-eef5ad6899db}\InProcServer32'
$values=@(
 Read-Value Registry64 $core ''
 Read-Value Registry32 $core ''
 Read-Value Registry64 'SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404' 'Layout File'
 Read-Value Registry64 'SYSTEM\CurrentControlSet\Control\Keyboard Layout' 'Scancode Map'
)
$stateFiles=foreach($relative in @('Fujitsu-JIS-Core\install-state.json','Fujitsu-JIS-SpaceKeys\state.json')){
 $path=Join-Path $env:ProgramData $relative
 $row=[ordered]@{File=$relative;Exists=(Test-Path -LiteralPath $path);State=$null;Error=$null}
 if($row.Exists){try{$row.State=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}catch{$row.Error=$_.Exception.Message}}
 [pscustomobject]$row
}
$os=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$report=[pscustomobject]@{SavedAt=(Get-Date -Format o);ReadOnly=$true;Process64Bit=[Environment]::Is64BitProcess;OS=[pscustomobject]@{Product=$os.ProductName;Build=$os.CurrentBuildNumber;UBR=$os.UBR};Values=$values;InstallStates=@($stateFiles)}
$path=Join-Path $PSScriptRoot ('Install-diagnostic-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.json')
$report|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $path -Encoding UTF8
Write-Host ('Report saved: '+$path)
Write-Host 'Read-only check complete. No settings changed; no restart required.'
