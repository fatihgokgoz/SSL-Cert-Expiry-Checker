# 🔐 SSL Sertifika Süresi Kontrol Scripti (PowerShell)

Bu script, belirlediğiniz domain’lerin SSL sertifikalarının geçerlilik süresini kontrol eder. Süresi yaklaşan sertifikalar için erken uyarı verir, rapor oluşturur ve log dosyası üretir.

---

## 🚀 Özellikler

- `domains.txt` dosyasından domain listesi okur
- Ping testi ile erişilebilirlik kontrolü yapar
- TCP 443 üzerinden SSL sertifika süresini sorgular
- Süresi yaklaşan domain'leri uyarır (varsayılan eşik: 30 gün)
- `.csv` raporu ve `.log` dosyası üretir
- Kurumsal ortamlarda kullanılabilecek şekilde geliştirilmiştir

---

## 🧰 Gereksinimler

- Windows PowerShell 5.1+
- İnternet bağlantısı
- `domains.txt` dosyası (her satıra bir domain gelecek şekilde)

---

## ⚙️ Kullanım

### 1. Dosyaları İndirin veya Kopyalayın

- `Check-SSL.ps1` → PowerShell scripti
- `domains.txt` → Kontrol edilecek domain listesi

### 2. `domains.txt` Dosyasını Düzenleyin

```txt
google.com
openai.com
api.bankanız.com
