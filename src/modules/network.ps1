# network.ps1 - Network diagnostics and cURL HTTP helpers
function myip {
    $geo = (Invoke-RestMethod -Uri 'https://ipinfo.io/json' -UseBasicParsing)
    $dim = $PSStyle.Foreground.BrightBlack
    $city = $PSStyle.Foreground.BrightCyan
    $val = $PSStyle.Foreground.BrightWhite
    $green = $PSStyle.Foreground.BrightGreen
    $r = $PSStyle.Reset
    Write-Host "${city}$($geo.city)${r}${dim}, ${r}${val}$($geo.region)${r}${dim} - ${r}${city}$($geo.country)${r}${dim} ($($geo.org))${r}"
    $geo.ip | Set-Clipboard
    Write-Host "${green}$($geo.ip)${r} ${dim}~ copied${r}"
}

function flushdns { ipconfig /flushdns }
function testport ($Host_, $Port) { Test-NetConnection -ComputerName $Host_ -Port $Port }

# cURL Helpers — Debug / latency
function curltime ($Url) { curl.exe -so NUL -w "`nDNS:     %{time_namelookup}s`nConnect: %{time_connect}s`nTLS:     %{time_appconnect}s`nTTFB:    %{time_starttransfer}s`nTotal:   %{time_total}s`nStatus:  %{http_code}`n" $Url }
function curlhead ($Url) { curl.exe -sI $Url @args }
function curlssl ($Domain) { curl.exe -vvI --silent "https://$Domain" --stderr - | Select-String '\*\s+(subject|issuer|expire|start date|SSL)' }
function curlstatus ($Url) { curl.exe -so NUL -w "%{http_code}`n" $Url }
function curlfollow ($Url) { curl.exe -sIL $Url | Select-String 'HTTP/|location:' }

# cURL Helpers — HTTP Verbs (JSON)
function cget ($Url) { curl.exe -s -H "Accept: application/json" $Url @args }
function cpost ($Url, $Body) { curl.exe -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d $Body $Url @args }
function cput ($Url, $Body) { curl.exe -s -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -d $Body $Url @args }
function cpatch ($Url, $Body) { curl.exe -s -X PATCH -H "Content-Type: application/json" -H "Accept: application/json" -d $Body $Url @args }
function cdel ($Url) { curl.exe -s -X DELETE -H "Accept: application/json" $Url @args }

# cURL Helpers — Download
function cdl ($Url) { curl.exe -L -O -C - --progress-bar $Url @args }
function cdlr ($Url) { curl.exe -L -O -C - --retry 3 --retry-delay 2 --progress-bar $Url @args }
