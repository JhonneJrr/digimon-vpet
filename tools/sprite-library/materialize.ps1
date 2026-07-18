$ErrorActionPreference = "Stop"
$plan = "C:\Users\felip\AppData\Local\Temp\claude\C--Users-felip-Documents-digimon\6db3e746-1555-40ab-8c22-07add866b6c2\scratchpad\plan"
$root = "C:\Users\felip\Documents\DigitalTamers02_extracted\organized"

Add-Type -Namespace Win32 -Name Links -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
public static extern bool CreateHardLink(string lpFileName, string lpExistingFileName, IntPtr lpSecurityAttributes);
'@

# clean slate (organized/ is fully regenerable; sources untouched)
if (Test-Path $root) { Write-Host "removing existing organized/ ..."; Remove-Item $root -Recurse -Force }
[System.IO.Directory]::CreateDirectory($root) | Out-Null

# ---- hardlinks ----
$hl = [System.IO.File]::ReadAllLines("$plan\hardlinks.tsv")
Write-Host "hardlinks to create: $($hl.Count)"
# pre-create dirs
$dirs = New-Object System.Collections.Generic.HashSet[string]
foreach ($line in $hl) {
    $t = $line.Split("`t")[1].Replace("/","\")
    $d = [System.IO.Path]::GetDirectoryName("$root\$t")
    [void]$dirs.Add($d)
}
foreach ($d in $dirs) { [System.IO.Directory]::CreateDirectory($d) | Out-Null }
Write-Host "dirs created: $($dirs.Count)"

$ok=0; $fail=0; $i=0
foreach ($line in $hl) {
    $p = $line.Split("`t")
    $src = $p[0]; $dst = "$root\" + $p[1].Replace("/","\")
    if ([Win32.Links]::CreateHardLink($dst, $src, [IntPtr]::Zero)) { $ok++ } else { $fail++ }
    $i++; if ($i % 10000 -eq 0) { Write-Host "  $i / $($hl.Count) (ok=$ok fail=$fail)" }
}
Write-Host "HARDLINKS: ok=$ok fail=$fail"

# ---- junctions (curated lines) ----
$jl = [System.IO.File]::ReadAllLines("$plan\junctions.tsv")
$jok=0
foreach ($line in $jl) {
    $p = $line.Split("`t")
    $link = "$root\" + $p[0].Replace("/","\")
    $target = "$root\" + $p[1].Replace("/","\")
    $parent = [System.IO.Path]::GetDirectoryName($link)
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    if (Test-Path $target) {
        New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop | Out-Null
        $jok++
    } else { Write-Host "  !! junction target missing: $target" }
}
Write-Host "JUNCTIONS: $jok / $($jl.Count)"

# ---- docs ----
Copy-Item "$plan\docs\README.md" "$root\README.md" -Force
Copy-Item "$plan\docs\LINES.md"  "$root\LINES.md"  -Force
Get-ChildItem "$plan\docs\lines" -Filter *__line.md | ForEach-Object {
    $lname = $_.Name -replace '__line\.md$',''
    $dest = "$root\lines\$lname\_line.md"
    [System.IO.Directory]::CreateDirectory("$root\lines\$lname") | Out-Null
    Copy-Item $_.FullName $dest -Force
}
Write-Host "DONE."
