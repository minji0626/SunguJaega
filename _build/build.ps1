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

# 아이콘 (24x24 선 아이콘). 페이지에서 {{ICON:이름}} 으로 사용
$iconPaths = @{
    phone   = '<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/>'
    home    = '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>'
    drop    = '<path d="M12 2.7s-6 6.6-6 11.3a6 6 0 0 0 12 0c0-4.7-6-11.3-6-11.3z"/>'
    file    = '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>'
    pin     = '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>'
    heart   = '<path d="M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.2a4.3 4.3 0 0 1 7.5 2.6C19.5 15.4 12 20 12 20z"/>'
    users   = '<path d="M16 20v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 18.5V20"/><circle cx="10" cy="7.5" r="3.5"/><path d="M20 20v-1.5a3.5 3.5 0 0 0-2.5-3.4M15.5 4.2a3.5 3.5 0 0 1 0 6.6"/>'
    shield  = '<path d="M12 3 5 6v5c0 4.5 3 8 7 10 4-2 7-5.5 7-10V6z"/><path d="m9 12 2 2 4-4"/>'
    clock   = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'
    chevron = '<path d="m9 6 6 6-6 6"/>'
    check   = '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>'
    menu    = '<path d="M4 7h16M4 12h16M4 17h16"/>'
}
function Get-Icon($name) {
    '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + $iconPaths[$name] + '</svg>'
}

$template    = Read-Text "$buildDir\template.html"
$contactBand = Read-Text "$buildDir\partials\contact-band.html"
$faq         = Read-Text "$buildDir\partials\faq.html"
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

    $html = $template.Replace('{{CONTENT}}', $body.Replace('{{CONTACT_BAND}}', $contactBand.TrimEnd()).Replace('{{FAQ}}', $faq.TrimEnd()))
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

    # 아이콘 치환
    $html = [regex]::Replace($html, '\{\{ICON:(\w+)\}\}', { param($m) if (-not $iconPaths.ContainsKey($m.Groups[1].Value)) { throw "알 수 없는 아이콘: $($m.Groups[1].Value)" }; Get-Icon $m.Groups[1].Value })

    # 남은 자리표시자가 있으면 실수이므로 중단
    if ($html -match '\{\{[A-Z_a-z]+\}\}') { throw "$($_.Name): 치환되지 않은 값 $($Matches[0])" }

    [System.IO.File]::WriteAllText((Join-Path $rootDir $_.Name), ($html -replace "`r?`n", "`r`n"), $utf8)
    Write-Host "built $($_.Name)"
}
