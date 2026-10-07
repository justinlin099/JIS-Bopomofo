$ErrorActionPreference='Stop'
$e=$null;$t=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path (Split-Path $PSScriptRoot -Parent) 'windows/SpaceKeys.ps1'),[ref]$t,[ref]$e)
if($e){throw $e}
$function=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Convert-ToSpaceMap'},$true)
if(!$function){throw 'Pure mapper function missing'}
. ([scriptblock]::Create($function.Extent.Text))
function Bytes($hex){[byte[]]@(for($i=0;$i -lt $hex.Length;$i+=2){[Convert]::ToByte($hex.Substring($i,2),16)})}
function Hex([byte[]]$b){([BitConverter]::ToString($b)).Replace('-','').ToLowerInvariant()}
$results=@()
foreach($case in @(
 @{Name='Empty';Before='';After='0000000000000000030000003900790039007b0000000000'},
 @{Name='KeepCapsToEscape';Before='00000000000000000200000001003a0000000000';After='00000000000000000400000001003a003900790039007b0000000000'},
 @{Name='ReplaceOnlyTwoSources';Before='0000000000000000040000000100790001003a0001007b0000000000';After='00000000000000000400000001003a003900790039007b0000000000'}
)){
 $actual=Hex (Convert-ToSpaceMap (Bytes $case.Before))
 $results+=[pscustomobject]@{Name=$case.Name;Passed=($actual -eq $case.After)}
}
foreach($bad in @('00000000','00000000000000000400000001003a0000000000','00000000000000000300000001003a0002003a0000000000')){
 $rejected=$false;try{$null=Convert-ToSpaceMap (Bytes $bad)}catch{$rejected=$true}
 $results+=[pscustomobject]@{Name='RejectMalformedOrDuplicate';Passed=$rejected}
}
$results|ConvertTo-Json|Set-Content (Join-Path $PSScriptRoot 'space-map-results.json') -Encoding UTF8
$results|Format-Table
if($results.Passed -contains $false){throw 'Pure mapping test failed'}
