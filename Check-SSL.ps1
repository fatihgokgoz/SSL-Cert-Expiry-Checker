<#
╔═════════════════════════════════════════════════════════════════╗
║      SSL Certificate Expiry Checker v2.1 (PowerShell)         ║
║      Middleware & Infra Ready | domain.txt destekli         ║
╚═════════════════════════════════════════════════════════════════╝

Author    : Fatih | Senior Middleware Administrator
Version   : 2.1
Created   : 2025-05-30
Platform  : Windows PowerShell 5.1+
Purpose   : Checks SSL expiry dates for a list of domains (from file)
License   : MIT
#>

# ======================= 🔧 CONFIGURATION ==========================

$domainFile = ".\domains.txt"  # Her satıra bir domain yaz
$thresholdDays = 30
$timeout = 5000 # milisaniye cinsinden TCP timeout
$logFile = ".\SSL_Check_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$report = @()

# ======================== 📂 DOMAIN INPUT ==========================

if (!(Test-Path $domainFile)) {
    Write-Host "❌ Domain listesi dosyası bulunamadı: $domainFile" -ForegroundColor Red
    exit
}

$domains = Get-Content $domainFile | Where-Object { $_.Trim() -ne "" }

if ($domains.Count -eq 0) {
    Write-Host "❌ domains.txt boş, en az bir domain giriniz." -ForegroundColor Red
    exit
}

Write-Host "`n🚀 Başlatıldı: SSL Sertifika Sağlık Taraması" -ForegroundColor Green
Write-Host "📅 Tarih: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host "📡 Kontrol edilecek domain sayısı: $($domains.Count)" -ForegroundColor Cyan
Write-Host "⏳ Uyarı eşiği: $thresholdDays gün" -ForegroundColor Yellow
Write-Host "--------------------------------------------------`n"

# ======================== 🔍 DOMAIN CHECK ==========================

foreach ($domain in $domains) {
    $domain = $domain.Trim()
    Write-Host "🌐 $domain kontrol ediliyor..." -ForegroundColor Cyan

    # 🧪 Ping ile ön kontrol
    if (-not (Test-Connection -Count 1 -Quiet -ComputerName $domain)) {
        Write-Warning "❌ $domain erişilemiyor (Ping başarısız)."
        $report += [pscustomobject]@{
            Domain         = $domain
            ExpiresOn      = "N/A"
            DaysRemaining  = "N/A"
            Status         = "❌ Ping Failed"
        }
        continue
    }

    try {
        $tcpClient = New-Object Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($domain, 443, $null, $null)

        if (-not $asyncResult.AsyncWaitHandle.WaitOne($timeout, $false)) {
            throw "Timeout"
        }

        $tcpClient.EndConnect($asyncResult)
        $sslStream = New-Object Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
        $sslStream.AuthenticateAsClient($domain)

        $cert     = $sslStream.RemoteCertificate
        $certData = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert
        $expiry   = $certData.NotAfter
        $daysLeft = ($expiry - (Get-Date)).Days

        $tcpClient.Close()

        $status = if ($daysLeft -le $thresholdDays) { "⚠️  Soon to Expire" } else { "✅ OK" }

        $report += [pscustomobject]@{
            Domain         = $domain
            ExpiresOn      = $expiry.ToString("yyyy-MM-dd")
            DaysRemaining  = $daysLeft
            Status         = $status
        }

    } catch {
        Write-Warning "❌ $domain için bağlantı veya sertifika alınamadı."
        $report += [pscustomobject]@{
            Domain         = $domain
            ExpiresOn      = "N/A"
            DaysRemaining  = "N/A"
            Status         = "❌ Connection/SSL Error"
        }
    }
}

# ===================== 📊 OUTPUT & LOGGING =========================

$report | Sort-Object DaysRemaining | Format-Table -AutoSize

# CSV & LOG export (isteğe bağlı)
$report | Export-Csv -Path ".\SSL_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation -Encoding UTF8

$report | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "`n📁 Log dosyası kaydedildi: $logFile" -ForegroundColor Gray
Write-Host "✅ Tarama tamamlandı. Sistem sağlığınız koruma altında." -ForegroundColor Green
