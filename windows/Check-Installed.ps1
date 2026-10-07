# Read-only report; no registry or DLL changes.
$ErrorActionPreference='Stop'
if(![Environment]::Is64BitProcess){throw 'Use the included 64-bit Check.cmd'}
$os=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Classes\CLSID\{25ecf786-a925-4706-a269-eef5ad6899db}\InProcServer32')
try{$core=$key.GetValue('')}finally{$key.Dispose()}
$key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Keyboard Layouts\00000404')
try{$layout=$key.GetValue('Layout File')}finally{$key.Dispose()}
$key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Keyboard Layout')
try{$map=$key.GetValue('Scancode Map');$hex=if($null -ne $map){[BitConverter]::ToString($map)}else{$null}}finally{$key.Dispose()}
$states=foreach($name in @('Fujitsu-JIS-Core\install-state.json','Fujitsu-JIS-SpaceKeys\state.json')){
 $path=Join-Path $env:ProgramData $name
 if(Test-Path -LiteralPath $path){$state=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json;[pscustomobject]@{File=$name;Status=$state.Status}}
}
$files=foreach($relative in @('System32\IME\IMETC\IMTCCORE.DLL','SysWOW64\IME\IMETC\IMTCCORE.DLL','System32\KBD106.DLL')){
 $path=Join-Path $env:SystemRoot $relative
 [pscustomobject]@{File=$relative;SHA256=(Get-FileHash -LiteralPath $path).Hash;Signature=[string](Get-AuthenticodeSignature -LiteralPath $path).Status}
}
$ctfmon=@(Get-Process ctfmon -ErrorAction SilentlyContinue)
$registered=try{[pscustomobject]@{File=$core;SHA256=(Get-FileHash -LiteralPath $core).Hash}}catch{[pscustomobject]@{File=$core;Unavailable=$_.Exception.Message}}
$modules=foreach($p in $ctfmon){
 try{
  $available=@($p.Modules|Where-Object {$null -ne $_})
  $matched=@(foreach($m in $available){if($m.FileName -match '(?i)(JisCoreRouter|ImTcCore)'){[pscustomobject]@{PID=$p.Id;File=$m.FileName;SHA256=(Get-FileHash -LiteralPath $m.FileName).Hash}}})
  if($matched.Count){$matched}else{[pscustomobject]@{PID=$p.Id;VisibleModuleCount=$available.Count;Unavailable='No matching module metadata was observable. This report cannot distinguish access limits from an unloaded component.'}}
 }catch{[pscustomobject]@{PID=$p.Id;Unavailable=$_.Exception.Message}}
}
$report=[pscustomobject]@{SavedAt=(Get-Date -Format o);ReadOnly=$true;OS=[pscustomobject]@{Product=$os.ProductName;Build=$os.CurrentBuildNumber;UBR=$os.UBR};CoreRegistration=$core;RegisteredComponent=$registered;KeyboardLayout=$layout;ScancodeMap=$hex;States=@($states);MicrosoftFiles=@($files);Ctfmon=@($ctfmon|Select-Object Id,SessionId);LoadedModules=@($modules)}
$out=Join-Path $PSScriptRoot ('Physical-JIS-report-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.json')
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $out -Encoding UTF8
Write-Host ('Report saved: '+$out)
