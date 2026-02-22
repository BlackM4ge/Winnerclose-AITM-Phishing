# 🕸️ Winnerclose AITM Phishing Analysis: The WhatsApp Hijack

**Analyst:** Bkm4ge  
**Date:** February 2026  
**Target:** WhatsApp Web Sessions  
**Category:** Cyber Threat Intelligence / Red Teaming  

![Status: Neutralized](https://img.shields.io/badge/Status-Neutralized-success)
![Type: AITM Phishing](https://img.shields.io/badge/Type-AITM_Phishing-red)
![Evasion: Browser DoS](https://img.shields.io/badge/Evasion-Browser_DoS-orange)

## 🎯 Overview
This repository contains the full Threat Intelligence analysis, raw artifacts, and Indicators of Compromise (IoCs) of a highly sophisticated **Adversary-in-the-Middle (AITM)** phishing campaign. 

The operation targets WhatsApp web sessions using dynamic Geo-Fencing, WebSockets for real-time OTP interception, and aggressive anti-analysis techniques (including a CPU-exhausting Browser DoS attack via Web Workers).



## ⛓️ Attack Kill Chain
1. **Delivery:** Lateral phishing via trusted WhatsApp channels using a fake dance competition lure (`/home/final2`).
2. **Traffic Distribution:** Redirection of engaged targets to the true exploitation server (`/login/code2`).
3. **Exploitation (AITM):** Instantiation of a persistent Engine.IO/WebSocket tunnel.
4. **Evasion:** IP profiling via `ipapi.co` to serve dynamic localized content or trigger a 1000-thread Web Worker DoS against security analysts.
5. **Action on Objectives:** Real-time theft of the 8-digit pairing code to hijack the WhatsApp session and propagate the infection.

## 📂 Repository Structure

| Directory | Description |
|---|---|
| 📄 **`README.md`** | Project overview and visual synthesis. |
| 📁 **`Docs/`** | Comprehensive Threat Intelligence Report and the "Patient Zero" Incident Log. |
| 📁 **`IoCs/`** | CSV and TXT files containing Network Indicators (Domains, IPs, ASNs) and File Hashes. |
| 📁 **`Artifacts/`** | Extracted and neutralized source code (`number.js`, `integrated.js`, DOM structures). |
| 📁 **`Scripts/`** | CLI extraction tools and curl methodologies used to bypass the TDS. |

## ⚠️ Ethical & Security Disclaimer
All artifacts, scripts, and documentation provided in this repository are strictly for **defensive analysis, research, and educational purposes**. 

The malicious payloads located in the `Artifacts/` directory have been neutralized and appended with `.txt` extensions to prevent accidental execution. **Do not execute, host, or deploy any of the provided code outside of an isolated, controlled sandbox environment.** The author assumes no responsibility for the misuse of this information.
