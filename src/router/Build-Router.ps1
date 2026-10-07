[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ZigExecutable,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$zig=(Resolve-Path -LiteralPath $ZigExecutable).ProviderPath
$output=[IO.Path]::GetFullPath($OutputDirectory)
$dll=Join-Path $output 'JisCoreRouter64.dll'
if(Test-Path -LiteralPath $dll){throw 'Choose a new output directory'}
New-Item -ItemType Directory -Path $output -Force|Out-Null
$previousGlobal=$env:ZIG_GLOBAL_CACHE_DIR;$previousLocal=$env:ZIG_LOCAL_CACHE_DIR
try{
 $env:ZIG_GLOBAL_CACHE_DIR=Join-Path $output 'zig-global-cache'
 $env:ZIG_LOCAL_CACHE_DIR=Join-Path $output 'zig-local-cache'
 & $zig cc (Join-Path $PSScriptRoot 'JisCoreRouter.c') (Join-Path $PSScriptRoot 'JisCoreRouter.def') -o $dll -shared -target x86_64-windows-gnu -O2 -g0 -Wall -lbcrypt -lole32
 if($LASTEXITCODE -ne 0){throw 'Zig failed'}
 [pscustomobject]@{Bits=64;Output=$dll;SHA256=(Get-FileHash -LiteralPath $dll).Hash;Registered=$false}
}finally{$env:ZIG_GLOBAL_CACHE_DIR=$previousGlobal;$env:ZIG_LOCAL_CACHE_DIR=$previousLocal}
