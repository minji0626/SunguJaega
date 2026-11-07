<#
    선구복지센터 홈페이지 빌드 스크립트

    _build/pages/*.html 의 본문을 _build/template.html 에 끼워 넣어
    저장소 루트에 완성된 HTML 파일을 만듭니다.
    센터 이름·전화·주소 등은 _build/site.json 한 곳만 고치면 모든 페이지에 반영됩니다.

    사용법 (저장소 루트에서):
        powershell -ExecutionPolicy Bypass -File _build\build.ps1
#>
$ErrorActionPreference = 'Stop'

$buildDir = $PSScriptRoot
$rootDir  = Split-Path $buildDir -Parent
$utf8     = New-Object System.Text.UTF8Encoding $false   # BOM 없는 UTF-8

function Read-Text($path) { [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) }

# 사이트 공통 정보 읽기
$site = Read-Text "$buildDir\site.json" | ConvertFrom-Json
$vars = [ordered]@{}
$site.PSObject.Properties | ForEach-Object { $vars[$_.Name] = $_.Value }

# 파생 값: 전화 링크용 숫자, 국제 표기, 지도 검색 링크, 연도
$vars['TEL']        = $vars['PHONE'] -replace '-', ''
$vars['PHONE_INTL'] = $vars['PHONE'].Substring(1)
$vars['FAX_INTL']   = $vars['FAX'].Substring(1)
$q = [uri]::EscapeDataString($vars['ADDRESS'])
$vars['NAVER_MAP_URL'] = "https://map.naver.com/p/search/$q"
$vars['KAKAO_MAP_URL'] = "https://map.kakao.com/?q=$q"
$vars['YEAR'] = (Get-Date).Year

$template    = Read-Text "$buildDir\template.html"
$contactBand = Read-Text "$buildDir\partials\contact-band.html"
$navKeys     = 'about', 'greeting', 'services', 'process', 'location'

Get-ChildItem "$buildDir\pages\*.html" | ForEach-Object {
    $raw = (Read-Text $_.FullName) -replace "`r`n", "`n"

    # 머리말(--- 위쪽 key: value)과 본문 분리
    $parts = $raw -split "`n---`n", 2
    $meta = @{}
    foreach ($line in $parts[0] -split "`n") {
        if ($line -match '^(\w+):\s?(.*)$') { $meta[$Matches[1]] = $Matches[2].Trim() }
    }
    $body = $parts[1].TrimEnd()

    # 404 페이지는 어느 경로에서든 열리므로 절대 경로(/) 사용
    $base = if ($meta['base']) { $meta['base'] } else { '' }
    $homeHref = if ($base) { '/' } else { './' }

    $html = $template.Replace('{{CONTENT}}', $body.Replace('{{CONTACT_BAND}}', $contactBand.TrimEnd()))
    $html = $html.Replace('{{BASE}}./', $homeHref)
    $html = $html.Replace('{{TITLE}}', $meta['title'])
    $html = $html.Replace('{{DESCRIPTION}}', $meta['description'])
    $html = $html.Replace('{{PATH}}', $meta['path'])
    $html = $html.Replace('{{BASE}}', $base)
    $html = $html.Replace('{{ROBOTS}}', $(if ($meta['noindex']) { "<meta name=`"robots`" content=`"noindex`" />`n    " } else { '' }))
    $html = $html.Replace('{{HEAD_EXTRA}}', $(if ($meta['head']) { "$($meta['head'])`n    " } else { '' }))

    # 현재 페이지 메뉴 표시
    foreach ($k in $navKeys) {
        $html = $html.Replace("{{NAV_$k}}", $(if ($meta['nav'] -eq $k) { ' aria-current="page"' } else { '' }))
    }

    # 센터 정보 치환
    foreach ($k in $vars.Keys) { $html = $html.Replace("{{$k}}", [string]$vars[$k]) }

    # 남은 자리표시자가 있으면 실수이므로 중단
    if ($html -match '\{\{[A-Z_a-z]+\}\}') { throw "$($_.Name): 치환되지 않은 값 $($Matches[0])" }

    [System.IO.File]::WriteAllText((Join-Path $rootDir $_.Name), ($html -replace "`r?`n", "`r`n"), $utf8)
    Write-Host "built $($_.Name)"
}
