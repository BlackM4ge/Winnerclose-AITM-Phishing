# Threat Intelligence Report: Fast-Chain Phishing Kit Analysis ("Winnerclose" Case)

**Date:** February 21, 2026  
**Analyst:** Bkm4ge  
**Target:** WhatsApp Web Sessions  
**Attack Vector:** Social Engineering (Lateral Phishing)  

## 1. Context (Incident Log): Patient Zero
The investigation was triggered by a critical alert: *"I've been hacked."*

The victim described a perfectly executed social engineering trap. The compromise originated from a link received through a trusted WhatsApp channel. The landing page simulated the finals of a dance competition, urging the user to vote for the best performance.

The psychological deception peaked during the validation phase. Under the guise of "verifying the legitimacy of the vote" and preventing fraud, the platform requested the victim's mobile phone number, subsequently generating a malicious QR code.

Upon scanning the frame, the infection manifested immediately. The victim witnessed a full Account Takeover (ATO): WhatsApp chats opening autonomously, malicious messages cascading to the entire contact list to harvest new victims, and critical conversations being silently archived or deleted in real-time to delay detection. 

The threat was contained only when the user executed the correct emergency protocol: forcibly logging out all linked devices via the mobile app and re-enabling Two-Factor Authentication (2FA). The communication tunnel was severed. What follows is the forensic autopsy of the architecture that armed this campaign.

## 2. Executive Summary
This document outlines the technical analysis of an advanced phishing campaign engineered for WhatsApp session hijacking. The initial infection vector leverages pre-existing trust chains, propagating via malicious links shared within trusted networks. Once control of the web session is acquired, the malware impersonates the victim to autonomously distribute the lure to other contacts, triggering a cascading infection.

## 3. Reconnaissance and Static Analysis (Phase 1)
The investigation began by isolating the primary lure URL: `https://winnerclose.pro/home/final2`. Preliminary visual analysis highlighted several Red Flags:
* **TLD Abuse:** The use of the `.pro` extension is a recurring pattern in spam and phishing campaigns, favored for its low registration costs.
* **Psychological Lures:** The domain nomenclature ("winnerclose") combined with the path (`/home/final2`) suggests a reward-based scenario, a foundational social engineering tactic.
* **Ephemeral Infrastructure:** The total absence of organic search engine indexing denotes a "throwaway" web architecture.

OSINT findings confirmed the elusive nature of the asset: `whois` queries yielded no results. Standard reputation systems (e.g., Talos Intelligence) did not detect critical threats, identifying only Cloudflare as the Network Owner—a standard technique for backend obfuscation. However, a VirusTotal scan returned a single "Phishing" detection by ESET, classifying it as `HTML/Phishing.WhatsApp.A Trojan`.

## 4. Weaponization and Delivery: The Lure (`/home/final2`)
Dynamic analysis in an isolated environment revealed the domain's facade. Inspection of HTTP transactions isolated a custom script named `integrated.js`. Deconstruction of the code revealed the following dynamics:
1. **UX Manipulation:** Creation of a credible user interface (including an FAQ section) designed to lower the victim's cognitive defenses.
2. **Trigger Mechanism:** Clicking the primary vote button (`.button-vote`) does not execute a data postback. Instead, it unhides a DOM element (`#warning-popup`) masked as a security verification step. The actual attack materializes within this pop-up.
3. **Anomalous Traffic & Redirects:** During exploration, the page attempts to fetch graphic resources from remote Russian domains (e.g., `allwebs.ru`). Completing the interaction forces a redirect to the true exploitation server: `https://winnerclose.pro/login/code2`.

## 5. Exploitation: The AITM Infrastructure (Phase 2)


Analysis of the second stage (`/login/code2`) exposed the **Adversary-in-the-Middle (AITM)** architecture. Network evidence demonstrates the use of asynchronous communications:
* **WebSocket Protocol:** The loading of `socket.io.js` and Engine.IO transactions (XHR requests with microscopic 1-2 byte payloads) confirm the establishment of a bidirectional, persistent Keep-Alive communication tunnel between the victim and the Command and Control (C2) server.

### 5.1. Core Payload Deconstruction (`number.js`)
Extraction of the `number.js` file (7 KB) provided the source code of the malicious logic. Reverse engineering identified three critical functions:
1. **Asynchronous Exfiltration:** The victim's input (phone number) is sanitized (`\D/g`) and transmitted to the C2 via WebSocket (`socket.emit("start_number")`) strictly when the tunnel is stable.
2. **Illicit Authorization:** The remote C2, operating as a headless client, generates the 8-character OTP required by WhatsApp and relays it back to the victim's DOM (`socket.on("code")`). Manual entry by the victim completes the remote authentication.
3. **OpSec (Dwell Time):** A timer closes the socket after exactly 5 minutes (`setTimeout(function() { socket.close(); ... }, 5 * 60 * 1000)`), mimicking WhatsApp Web's legitimate security timeout to limit the C2's network footprint.

### 5.2. Analyst Telemetry and Anti-Analysis Defenses (Evasion)
The true sophistication of the kit emerges from its active defenses:
* **Geo-Fencing and Fingerprinting:** The script executes an API call to `ipapi.co/json/`. Besides dynamically pre-filling the country calling code based on the JSON response (e.g., `+39` for Italy), the C2 ingests the Autonomous System Number (ASN) data.
* **Browser DoS (Denial of Service):** If the detected ASN belongs to a Datacenter, a Tor node, or a security vendor (e.g., `AS212238 - Datacamp Limited`), the IP is classified as *synthetic traffic*. In response, the C2 emits the `surprise` event via socket. This triggers the simultaneous generation of 1,000 Web Workers on the analyst's browser, executing infinite loops of heavy mathematical calculations. The result is instant CPU exhaustion (100%) and the crash of the analysis sandbox.

## 6. Post-Exploitation and Risk Assessment
The theft of the session token grants the attacker privileges equal to the legitimate user on the web interface.
* **Primary Logical Impact:** Data harvesting from chat history and attachments, Business Messaging Compromise (impersonation in corporate groups), lateral phishing propagation, and tactical obfuscation (silently archiving compromised chats).
* **Endpoint Compromise Risk:** Although the stolen session token does not provide local OS execution privileges (RCE), the hijacked WhatsApp account acts as a formidable Delivery Vector. The forwarding of disguised executable artifacts, if downloaded and executed by trusted contacts (or by the victim on a corporate workstation), grants the adversary Initial Access to the internal network.

**Summary:** The technical attack surface is limited to the messaging service, but the logical attack surface expands to any device on which the victim's contacts download the attacker's payloads.
