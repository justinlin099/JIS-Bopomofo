# Build only: read a known original DLL and create a separate experimental copy.
# Does not load DLLs, register components, alter settings or replace source files.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$SourceDll,
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string]$RecipeFile=(Join-Path $PSScriptRoot 'table7-build-recipes.json')
)
$ErrorActionPreference='Stop'
function Hash-Bytes([byte[]]$bytes){
 $hash=[Security.Cryptography.SHA256]::Create()
 try{([BitConverter]::ToString($hash.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$hash.Dispose()}
}
$recipeDocument=Get-Content -LiteralPath $RecipeFile -Raw -Encoding UTF8|ConvertFrom-Json
if($recipeDocument.format -ne 1 -or $recipeDocument.buildOnly -ne $true){throw 'Unsupported recipe format'}
$source=(Resolve-Path -LiteralPath $SourceDll).ProviderPath
$original=[IO.File]::ReadAllBytes($source)
$sourceHash=Hash-Bytes $original
$matching=@($recipeDocument.recipes|Where-Object sourceSHA256 -eq $sourceHash)
if($matching.Count -ne 1){throw "Unsupported original DLL SHA256: $sourceHash. No file or setting was changed."}
$recipe=$matching[0]
if($original.Length -ne $recipe.sourceLength -or $recipe.outputLength -lt $original.Length -or $recipe.outputLength -gt 4MB){throw 'Invalid recipe lengths'}
if($recipe.output -notmatch '^ImTcCore-JIS-Table7-(lab64|lab32|5856-64|5856-32|5794-64|5794-32)\.dll$'){throw 'Unexpected output filename'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
$target=Join-Path $output $recipe.output
if($target -ieq $source){throw 'Source replacement is prohibited'}
if(Test-Path -LiteralPath $target){throw 'Output already exists; choose a new output directory. No overwrite was performed.'}
$bytes=New-Object byte[] ([int]$recipe.outputLength)
[Array]::Copy($original,$bytes,$original.Length)
$lastEnd=0
foreach($edit in $recipe.edits){
 $before=[Convert]::FromBase64String($edit.before);$after=[Convert]::FromBase64String($edit.after);$offset=[int]$edit.offset
 if($offset -lt $lastEnd -or $before.Length -eq 0 -or $before.Length -ne $after.Length -or $offset+$before.Length -gt $original.Length){throw 'Invalid or overlapping patch range'}
 for($i=0;$i -lt $before.Length;$i++){if($original[$offset+$i] -ne $before[$i]){throw 'Patch source bytes differ'}}
 [Array]::Copy($after,0,$bytes,$offset,$after.Length);$lastEnd=$offset+$after.Length
}
$append=[Convert]::FromBase64String($recipe.append)
if($append.Length -ne $bytes.Length-$original.Length){throw 'Invalid appended data length'}
[Array]::Copy($append,0,$bytes,$original.Length,$append.Length)
if((Hash-Bytes $bytes) -ne $recipe.outputSHA256){throw 'Final DLL hash mismatch; nothing written'}
New-Item -ItemType Directory -Path $output -Force|Out-Null
$temporary=Join-Path $output ([Guid]::NewGuid().ToString('N')+'.building')
try {
 $stream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush()}finally{$stream.Dispose()}
 [IO.File]::Move($temporary,$target)
}finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force}}
[pscustomobject]@{BuildOnly=$true;Variant=$recipe.variant;SourceSHA256=$sourceHash;OutputSHA256=$recipe.outputSHA256;Output=$target;Registered=$false;OriginalUnchanged=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ieq $sourceHash)}
