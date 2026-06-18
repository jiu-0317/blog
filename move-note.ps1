# ===== 여기 두 줄만 본인 환경에 맞게 수정 =====
$Note        = "C:\내옵시디언볼트\어떤노트.md"   # 옮길 노트 1개
$VaultAttach = "C:\내옵시디언볼트\assets"          # 옵시디언에서 이미지가 저장되는 폴더
# (선택) content 안에서 노트를 둘 하위 폴더. 최상위면 "" 로 두기
$SubFolder   = ""
# ============================================

$ContentDir = "D:\quartz\content"
$AssetsDir  = Join-Path $ContentDir "assets"

# 1) 노트 복사
$destDir = if ($SubFolder) { Join-Path $ContentDir $SubFolder } else { $ContentDir }
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item $Note -Destination $destDir -Force
Write-Host "노트 복사됨 -> $destDir"

# 2) 노트가 쓰는 이미지 이름 추출 ( ![[...]] 와 ![](...) 둘 다 지원 )
$text = Get-Content $Note -Raw
$names = @()
$names += [regex]::Matches($text, '!\[\[([^\]\|]+?)(\|[^\]]*)?\]\]') | ForEach-Object { $_.Groups[1].Value.Trim() }
$names += [regex]::Matches($text, '!\[[^\]]*\]\(([^)]+)\)')          | ForEach-Object { [System.IO.Path]::GetFileName($_.Groups[1].Value.Trim()) }
$names = $names | Sort-Object -Unique

# 3) 해당 이미지들만 content\assets 로 복사 (볼트 하위 전체에서 이름으로 검색)
New-Item -ItemType Directory -Force -Path $AssetsDir | Out-Null
foreach ($n in $names) {
    $src = Get-ChildItem -Path $VaultAttach -Recurse -Filter $n -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($src) {
        Copy-Item $src.FullName -Destination $AssetsDir -Force
        Write-Host "이미지 복사됨 -> $n"
    } else {
        Write-Warning "이미지 못 찾음: $n"
    }
}
Write-Host "`n완료. 이미지 $($names.Count)개 처리"
