<#
.SYNOPSIS
Script di Estrazione Artefatti per Campagna AITM "Winnerclose"

.DESCRIPTION
Questo script è progettato per scaricare in sicurezza i payload JavaScript dal server C2.
Implementa tecniche di evasione di base contro i Traffic Distribution Systems (TDS),
effettuando lo spoofing dell'User-Agent (simulando un dispositivo iOS) e iniettando
un Referer credibile per bypassare i controlli di hotlinking e geofencing.

.NOTES
Analyst: Bkm4ge
Date: 2026-02-21
Target: https://winnerclose.pro
#>

# Definizione dei target (Neutralizzati in output)
$TargetUrl = "https://winnerclose.pro/static/js/number.js" 
$OutFile = "..\Artifacts\number.js.txt"

# Spoofing dell'ambiente di navigazione (Mobile/WhatsApp Web context)
$Headers = @{
    "User-Agent"      = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
    "Accept-Language" = "it-IT,it;q=0.9"
    "Referer"         = "https://winnerclose.pro/home/final2" 
}

Write-Host "[*] Inizializzazione connessione verso il C2: $TargetUrl" -ForegroundColor Cyan

try {
    # Disabilitazione temporanea dei controlli SSL in caso di certificati C2 auto-firmati o anomali
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    # Esecuzione della richiesta HTTP GET
    Invoke-WebRequest -Uri $TargetUrl -Headers $Headers -OutFile $OutFile
    
    Write-Host "[+] Estrazione completata. L'artefatto è stato salvato e neutralizzato come .txt" -ForegroundColor Green

} catch {
    Write-Host "[-] Estrazione fallita. Il C2 potrebbe essere offline o aver bloccato l'IP (Intervento del Geo-Fencing o ASN Block)." -ForegroundColor Red
    Write-Host $_.Exception.Message
}
