# =====================================================================
# HTML -> DOCX (OOXML) converter for the De 3 report.
# Handles the tag subset used in docs\BaoCao_De3_WordPress.html:
# h1-h3, p, ul, ol, table/caption, pre, b/strong, i/em, code.
# Produces a real .docx (zip) with styles, footer page numbers and a
# TOC field that Word refreshes when the file is opened.
# =====================================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = $PSScriptRoot
$htmlPath = Join-Path $root "docs\BaoCao_De3_WordPress.html"
$outPath  = Join-Path $root "BaoCao_De3_WordPress_QuangBa.docx"
$work     = Join-Path $env:TEMP ("docxbuild_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
function Esc([string]$s) {
    if ($null -eq $s) { return "" }
    $s = $s -replace '&nbsp;', ' '
    $s = $s -replace '&lt;', '<'
    $s = $s -replace '&gt;', '>'
    $s = $s -replace '&quot;', '"'
    $s = $s -replace '&amp;', '&'
    $s = $s -replace '&', '&amp;'
    $s = $s -replace '<', '&lt;'
    $s = $s -replace '>', '&gt;'
    return $s
}

function Strip-Tags([string]$s) {
    return [regex]::Replace($s, '<[^>]+>', '')
}

# Inline markup -> run XML
function Inline([string]$text, [bool]$forceBold = $false, [bool]$forceItalic = $false, [bool]$mono = $false) {
    $sb = New-Object System.Text.StringBuilder
    $bold = $forceBold
    $ital = $forceItalic
    $code = $mono
    $ms = [regex]::Matches($text, '(<[^>]+>)|([^<]+)')
    foreach ($m in $ms) {
        if ($m.Groups[1].Success) {
            $tag = $m.Groups[1].Value.ToLower()
            switch -regex ($tag) {
                '^<(b|strong)(\s|>)' { $bold = $true;  continue }
                '^</(b|strong)'       { $bold = $false; continue }
                '^<(i|em)(\s|>)'      { $ital = $true;  continue }
                '^</(i|em)'           { $ital = $false; continue }
                '^<code'              { $code = $true;  continue }
                '^</code'             { $code = $false; continue }
                '^<br'                { [void]$sb.Append('<w:r><w:br/></w:r>'); continue }
                default               { continue }
            }
        }
        $t = $m.Groups[2].Value
        if ([string]::IsNullOrWhiteSpace($t)) {
            if ($t.Length -gt 0) { [void]$sb.Append('<w:r><w:t xml:space="preserve">' + (Esc $t) + '</w:t></w:r>') }
            continue
        }
        $t = $t -replace '^\s+', ' '
        $rpr = '<w:rPr>'
        if ($code) { $rpr += '<w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:sz w:val="21"/><w:szCs w:val="21"/>' }
        else       { $rpr += '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>' }
        if ($bold) { $rpr += '<w:b/>' }
        if ($ital) { $rpr += '<w:i/>' }
        $rpr += '</w:rPr>'
        [void]$sb.Append('<w:r>' + $rpr + '<w:t xml:space="preserve">' + (Esc $t) + '</w:t></w:r>')
    }
    return $sb.ToString()
}

function Para([string]$style, [string]$runs, [string]$extraPPr = '') {
    $ppr = '<w:pPr>'
    if ($style) { $ppr += '<w:pStyle w:val="' + $style + '"/>' }
    $ppr += $extraPPr + '</w:pPr>'
    return '<w:p>' + $ppr + $runs + '</w:p>'
}

# Read HTML
$html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$bodyMatch = [regex]::Match($html, '(?s)<body>(.*)</body>')
if (-not $bodyMatch.Success) { throw "body not found" }
$body = $bodyMatch.Groups[1].Value
$body = [regex]::Replace($body, '(?s)<!--.*?-->', '')
$body = [regex]::Replace($body, '(?s)<style.*?</style>', '')

$doc = New-Object System.Text.StringBuilder
$blockPattern = '(?s)<(h1|h2|h3|p|pre|ul|ol|table)\b([^>]*)>(.*?)</\1>'
$olCounter = 0

foreach ($m in [regex]::Matches($body, $blockPattern)) {
    $tag   = $m.Groups[1].Value.ToLower()
    $attrs = $m.Groups[2].Value
    $inner = $m.Groups[3].Value

    switch ($tag) {
        'h1' { [void]$doc.Append((Para 'Heading1' (Inline $inner))) ; $olCounter = 0 }
        'h2' { [void]$doc.Append((Para 'Heading2' (Inline $inner))) ; $olCounter = 0 }
        'h3' { [void]$doc.Append((Para 'Heading3' (Inline $inner))) ; $olCounter = 0 }

        'p' {
            # %%TOC%% -> real TOC field
            if ($inner -match '%%TOC%%') {
                $fld = '<w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r>' +
                       '<w:r><w:instrText xml:space="preserve"> TOC \o "1-3" \h \z \u </w:instrText></w:r>' +
                       '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
                       '<w:r><w:rPr><w:i/></w:rPr><w:t xml:space="preserve">(Muc luc se duoc cap nhat khi mo tep - nhan Ctrl+A roi F9 neu can)</w:t></w:r>' +
                       '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
                [void]$doc.Append((Para '' $fld '<w:ind w:firstLine="0"/>'))
                continue
            }

            $ppr = ''
            $isNoIndent = $attrs -match 'class="[^"]*noindent'
            $jc = ''
            $sz = ''
            $bold = $false
            $center = $false
            if ($attrs -match 'style="([^"]*)"') {
                $st = $matches[1]
                if ($st -match 'text-align:\s*center') { $center = $true }
                if ($st -match 'font-size:\s*(\d+)pt') { $sz = $matches[1] }
                if ($st -match 'font-weight:\s*bold')  { $bold = $true }
                if ($st -match 'page-break-before:\s*always') { $ppr += '<w:pageBreakBefore/>' }
                if ($st -match 'text-indent:\s*-\s*[\d.]+cm') { $isNoIndent = $true }
            }
            if ($center) { $jc = 'center' }
            if ($ppr -eq '' -or $isNoIndent) { $ppr += '<w:ind w:firstLine="0"/>' } elseif (-not $isNoIndent) { $ppr += '<w:ind w:firstLine="709"/>' }
            if ($isNoIndent -and $ppr -notmatch 'firstLine') { $ppr += '<w:ind w:firstLine="0"/>' }
            $runs = Inline $inner $bold $false
            if ($sz -or $jc) {
                $extra = ''
                if ($sz)   { $extra += '<w:sz w:val="' + ([int]$sz * 2) + '"/><w:szCs w:val="' + ([int]$sz * 2) + '"/>' }
                if ($bold) { $extra += '<w:b/>' }
                if ($jc)   { $extra += '<w:jc w:val="' + $jc + '"/>' }
                # wrap runs with extra run properties is complex; apply to paragraph mark instead
                $ppr += '<w:rPr>' + $extra + '</w:rPr>'
            }
            # re-render runs with size/bold applied when needed
            if ($sz -or $bold) {
                $runs = ''
                $ms2 = [regex]::Matches($inner, '(<[^>]+>)|([^<]+)')
                $b2 = $bold; $i2 = $false; $c2 = $false
                $rsb = New-Object System.Text.StringBuilder
                foreach ($mm in $ms2) {
                    if ($mm.Groups[1].Success) {
                        $tg = $mm.Groups[1].Value.ToLower()
                        if ($tg -match '^<(b|strong)(\s|>)') { $b2 = $true;  continue }
                        if ($tg -match '^</(b|strong)')      { $b2 = $false; continue }
                        if ($tg -match '^<(i|em)(\s|>)')      { $i2 = $true;  continue }
                        if ($tg -match '^</(i|em)')           { $i2 = $false; continue }
                        if ($tg -match '^<code')              { $c2 = $true;  continue }
                        if ($tg -match '^</code')             { $c2 = $false; continue }
                        continue
                    }
                    $tt = $mm.Groups[2].Value
                    if ([string]::IsNullOrWhiteSpace($tt)) { continue }
                    $rpr = '<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>'
                    if ($sz) { $rpr += '<w:sz w:val="' + ([int]$sz * 2) + '"/><w:szCs w:val="' + ([int]$sz * 2) + '"/>' }
                    if ($b2) { $rpr += '<w:b/>' }
                    if ($i2) { $rpr += '<w:i/>' }
                    $rpr += '</w:rPr>'
                    [void]$rsb.Append('<w:r>' + $rpr + '<w:t xml:space="preserve">' + (Esc ($tt -replace '\s+', ' ')) + '</w:t></w:r>')
                }
                $runs = $rsb.ToString()
            }
            [void]$doc.Append((Para '' $runs $ppr))
            $olCounter = 0
        }

        'pre' {
            # Preserve line breaks: each source line becomes a run,
            # separated by <w:br/> so Word does not collapse whitespace.
            $txt = Strip-Tags $inner
            $txt = $txt -replace "`r`n", "`n"
            $lines = New-Object System.Collections.Generic.List[string]
            foreach ($ln in ($txt -split "`n")) { $lines.Add($ln) }
            while ($lines.Count -gt 0 -and $lines[0].Trim() -eq '') { $lines.RemoveAt(0) }
            while ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim() -eq '') { $lines.RemoveAt($lines.Count - 1) }
            $psb = New-Object System.Text.StringBuilder
            for ($k = 0; $k -lt $lines.Count; $k++) {
                if ($k -gt 0) { [void]$psb.Append('<w:r><w:br/></w:r>') }
                [void]$psb.Append('<w:r><w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr><w:t xml:space="preserve">' + (Esc $lines[$k]) + '</w:t></w:r>')
            }
            [void]$doc.Append((Para 'Code' $psb.ToString()))
            $olCounter = 0
        }

        'ul' {
            foreach ($li in [regex]::Matches($inner, '(?s)<li>(.*?)</li>')) {
                $runs = '<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/></w:rPr><w:t xml:space="preserve">â€¢  </w:t></w:r>' + (Inline $li.Groups[1].Value)
                [void]$doc.Append((Para 'Normal' $runs '<w:ind w:left="567" w:hanging="284"/>'))
            }
            $olCounter = 0
        }

        'ol' {
            $i = 0
            foreach ($li in [regex]::Matches($inner, '(?s)<li>(.*?)</li>')) {
                $i++
                $runs = '<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/></w:rPr><w:t xml:space="preserve">' + $i + '.  </w:t></w:r>' + (Inline $li.Groups[1].Value)
                [void]$doc.Append((Para 'Normal' $runs '<w:ind w:left="567" w:hanging="284"/>'))
            }
            $olCounter = 0
        }

        'table' {
            $capMatch = [regex]::Match($inner, '(?s)<caption>(.*?)</caption>')
            if ($capMatch.Success) {
                $capRuns = '<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:i/><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">' + (Esc (Strip-Tags $capMatch.Groups[1].Value).Trim()) + '</w:t></w:r>'
                [void]$doc.Append((Para 'Normal' $capRuns '<w:jc w:val="center"/><w:ind w:firstLine="0"/><w:spacing w:after="60"/>'))
            }
            $tbl = New-Object System.Text.StringBuilder
            [void]$tbl.Append('<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders>' +
                '<w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '<w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '<w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>' +
                '</w:tblBorders><w:tblLayout w:type="autofit"/></w:tblPr><w:tblGrid/>')
            foreach ($tr in [regex]::Matches($inner, '(?s)<tr>(.*?)</tr>')) {
                [void]$tbl.Append('<w:tr>')
                foreach ($tc in [regex]::Matches($tr.Groups[1].Value, '(?s)<(td|th)([^>]*)>(.*?)</\1>')) {
                    $isTh = $tc.Groups[1].Value -eq 'th'
                    $cellInner = $tc.Groups[3].Value
                    $tcPr = '<w:tcPr><w:tcW w:w="0" w:type="auto"/>'
                    if ($isTh) { $tcPr += '<w:shd w:val="clear" w:color="auto" w:fill="E8E8E8"/>' }
                    $tcPr += '</w:tcPr>'
                    $cellRuns = Inline $cellInner $isTh $false
                    $cellPPr = '<w:pPr><w:pStyle w:val="TableText"/>'
                    if ($isTh) { $cellPPr += '<w:jc w:val="center"/>' }
                    $cellPPr += '</w:pPr>'
                    [void]$tbl.Append('<w:tc>' + $tcPr + '<w:p>' + $cellPPr + $cellRuns + '</w:p></w:tc>')
                }
                [void]$tbl.Append('</w:tr>')
            }
            [void]$tbl.Append('</w:tbl>')
            [void]$doc.Append($tbl.ToString())
            # spacer paragraph after table (Word needs a paragraph between tables)
            [void]$doc.Append('<w:p><w:pPr><w:spacing w:after="0"/><w:rPr><w:sz w:val="10"/></w:rPr></w:pPr></w:p>')
        }
    }
}

# ---------------------------------------------------------------------
# Package parts
# ---------------------------------------------------------------------
$sectPr = '<w:sectPr><w:footerReference w:type="default" r:id="rId4"/>' +
          '<w:pgSz w:w="11906" w:h="16838"/>' +
          '<w:pgMar w:top="1418" w:right="1418" w:bottom="1418" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/>' +
          '</w:sectPr>'

$documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' +
'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
'<w:body>' + $doc.ToString() + $sectPr + '</w:body></w:document>'

$stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
'<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>' +
'<w:sz w:val="26"/><w:szCs w:val="26"/><w:lang w:val="vi-VN"/></w:rPr></w:rPrDefault>' +
'<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="360" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>' +

'<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/>' +
'<w:pPr><w:spacing w:after="120" w:line="360" w:lineRule="auto"/><w:ind w:firstLine="709"/><w:jc w:val="both"/></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr></w:style>' +

'<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>' +
'<w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:pageBreakBefore/>' +
'<w:spacing w:before="240" w:after="240"/><w:ind w:firstLine="0"/><w:jc w:val="center"/><w:outlineLvl w:val="0"/></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style>' +

'<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/>' +
'<w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/>' +
'<w:spacing w:before="240" w:after="120"/><w:ind w:firstLine="0"/><w:jc w:val="left"/><w:outlineLvl w:val="1"/></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>' +

'<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/>' +
'<w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/>' +
'<w:spacing w:before="200" w:after="100"/><w:ind w:firstLine="0"/><w:jc w:val="left"/><w:outlineLvl w:val="2"/></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:i/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr></w:style>' +

'<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:qFormat/>' +
'<w:pPr><w:spacing w:before="60" w:after="120" w:line="240" w:lineRule="auto"/><w:ind w:firstLine="0" w:left="113"/>' +
'<w:jc w:val="left"/><w:shd w:val="clear" w:color="auto" w:fill="F5F5F5"/><w:pBdr>' +
'<w:top w:val="single" w:sz="4" w:space="4" w:color="BBBBBB"/><w:left w:val="single" w:sz="4" w:space="4" w:color="BBBBBB"/>' +
'<w:bottom w:val="single" w:sz="4" w:space="4" w:color="BBBBBB"/><w:right w:val="single" w:sz="4" w:space="4" w:color="BBBBBB"/>' +
'</w:pBdr></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr></w:style>' +

'<w:style w:type="paragraph" w:styleId="TableText"><w:name w:val="Table Text"/><w:basedOn w:val="Normal"/>' +
'<w:pPr><w:spacing w:before="40" w:after="40" w:line="264" w:lineRule="auto"/><w:ind w:firstLine="0" w:left="0"/><w:jc w:val="left"/></w:pPr>' +
'<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style>' +
'</w:styles>'

$footerXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
'<w:p><w:pPr><w:jc w:val="center"/><w:ind w:firstLine="0"/></w:pPr>' +
'<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="22"/></w:rPr>' +
'<w:fldChar w:fldCharType="begin"/></w:r>' +
'<w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>' +
'<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
'<w:r><w:t>1</w:t></w:r>' +
'<w:r><w:fldChar w:fldCharType="end"/></w:r>' +
'</w:p></w:ftr>'

$settingsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
'<w:updateFields w:val="true"/><w:defaultTabStop w:val="709"/>' +
'<w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat>' +
'</w:settings>'

$contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
'<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
'<Default Extension="xml" ContentType="application/xml"/>' +
'<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
'<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' +
'<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>' +
'<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
'<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
'<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' +
'</Types>'

$rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
'<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
'<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' +
'</Relationships>'

$docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
'<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>' +
'<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>' +
'</Relationships>'

$coreXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
'<dc:title>Bao cao De 3 - Website Quang ba San pham (WordPress)</dc:title>' +
'<dc:creator>Phung Duy Hoang</dc:creator>' +
'<cp:lastModifiedBy>Phung Duy Hoang</cp:lastModifiedBy>' +
'<dcterms:created xsi:type="dcterms:W3CDTF">2026-10-25T10:00:00Z</dcterms:created>' +
'<dcterms:modified xsi:type="dcterms:W3CDTF">2026-10-25T10:00:00Z</dcterms:modified>' +
'</cp:coreProperties>'

$appXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
'<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">' +
'<Application>Microsoft Office Word</Application><Company>DH CNTT va Truyen thong</Company>' +
'</Properties>'

# Write parts
$utf8 = New-Object System.Text.UTF8Encoding($false)
function WritePart([string]$rel, [string]$content) {
    $full = Join-Path $work $rel
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($full, $content, $utf8)
}

WritePart '[Content_Types].xml' $contentTypes
WritePart '_rels\.rels' $rootRels
WritePart 'word\document.xml' $documentXml
WritePart 'word\styles.xml' $stylesXml
WritePart 'word\settings.xml' $settingsXml
WritePart 'word\footer1.xml' $footerXml
WritePart 'word\_rels\document.xml.rels' $docRels
WritePart 'docProps\core.xml' $coreXml
WritePart 'docProps\app.xml' $appXml

# Zip -> .docx  (entry names MUST use forward slashes per OOXML/OPC)
if (Test-Path $outPath) { Remove-Item $outPath -Force }
$fs = [System.IO.File]::Open($outPath, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
$order = @('[Content_Types].xml', '_rels\.rels', 'word\document.xml', 'word\styles.xml',
           'word\settings.xml', 'word\footer1.xml', 'word\_rels\document.xml.rels',
           'docProps\core.xml', 'docProps\app.xml')
foreach ($rel in $order) {
    $entryName = $rel -replace '\\', '/'
    $entry = $zip.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $st = $entry.Open()
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $work $rel))
    $st.Write($bytes, 0, $bytes.Length)
    $st.Close()
}
$zip.Dispose()
$fs.Close()

$size = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
Write-Output ("SAVED: " + $outPath)
Write-Output ("SIZE : " + $size + " KB")
Write-Output ("PARAGRAPHS: " + ([regex]::Matches($doc.ToString(), '<w:p>')).Count)
Write-Output ("TABLES: " + ([regex]::Matches($doc.ToString(), '<w:tbl>')).Count)

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

