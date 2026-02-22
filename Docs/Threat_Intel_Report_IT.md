# Threat Intelligence Report: Analisi Phishing Kit a Catena di Infezione Rapida (Caso "Winnerclose")

**Data:** 21 Febbraio 2026  
**Analista:** Bkm4ge  
**Target:** Sessioni Web WhatsApp  
**Vettore di Compromissione:** Ingegneria Sociale (Lateral Phishing)  

## 1. Contesto (Incident Log): Il Paziente Zero
L'indagine ha preso avvio da un messaggio di emergenza critico: *"Mi hanno hackerato"*.

La vittima ha descritto l'anatomia perfetta di una trappola di ingegneria sociale. La compromissione è originata da un link ricevuto attraverso un canale WhatsApp considerato sicuro. La pagina di atterraggio simulava la finale di un innocuo concorso di danza, invitando l'utente a votare per la migliore esibizione. 

L'inganno psicologico ha raggiunto il culmine nella fase di validazione. Con il pretesto di "verificare la liceità del voto" e prevenire frodi, la piattaforma ha richiesto l'inserimento del numero di telefono cellulare, generando successivamente un QR Code malevolo.

Alla scansione del frame, l'infezione si è manifestata immediatamente. La vittima ha assistito a un Account Takeover (ATO) completo: chat di WhatsApp che si aprivano autonomamente, messaggi malevoli propagati a cascata verso l'intera rubrica per mietere nuove vittime, e conversazioni critiche archiviate o cancellate in tempo reale per ritardare il rilevamento dell'anomalia. 

La minaccia è stata contenuta solo quando l'utente ha eseguito il protocollo di emergenza corretto: disconnessione forzata di tutti i dispositivi collegati tramite l'app mobile e riattivazione dell'Autenticazione a Due Fattori (2FA). Il tunnel di comunicazione è stato reciso. Quello che segue è l'autopsia forense dell'architettura che ha armato questa campagna.

## 2. Executive Summary
Il presente documento espone l'analisi tecnica di una campagna di phishing avanzata, architettata per il dirottamento di sessioni WhatsApp. Il vettore di infezione iniziale sfrutta catene di fiducia preesistenti, propagandosi tramite link malevoli condivisi all'interno di reti fidate. Acquisito il controllo della sessione web, il malware si appropria dell'identità della vittima per distribuire autonomamente l'esca ad altri contatti, innescando un contagio a cascata.

## 3. Reconnaissance e Analisi Statica (Fase 1)
L'indagine è iniziata con l'isolamento dell'URL esca primario: `https://winnerclose.pro/home/final2`. L'analisi visiva preliminare ha evidenziato diverse Red Flag:
* **Abuso del TLD:** L'utilizzo dell'estensione `.pro` è un pattern ricorrente in campagne spam e phishing, favorito dai bassi costi di registrazione.
* **Esche Psicologiche:** La nomenclatura del dominio ("winnerclose") unita al path (`/home/final2`) suggerisce uno scenario di ricompensa, una tattica basilare di ingegneria sociale.
* **Infrastruttura Effimera:** La totale assenza di indicizzazione organica sui motori di ricerca denota un'architettura web "usa e getta".

I riscontri OSINT hanno confermato la natura elusiva dell'asset: le interrogazioni `whois` non hanno prodotto risultati. I sistemi di reputazione standard (es. Talos Intelligence) non hanno rilevato minacce, identificando unicamente Cloudflare come Network Owner (tecnica standard per l'offuscamento del backend). Tuttavia, una scansione su VirusTotal ha restituito una singola rilevazione per "Phishing" da parte di ESET, classificandolo come `HTML/Phishing.WhatsApp.A Trojan`.

## 4. Weaponization e Delivery: L'Esca (`/home/final2`)
L'analisi dinamica in ambiente isolato ha svelato la facciata del dominio. L'ispezione delle transazioni HTTP ha permesso di isolare uno script custom denominato `integrated.js`. La decostruzione del codice ha rivelato le seguenti dinamiche:
1. **Manipolazione UX:** Creazione di un'interfaccia utente credibile (inclusa una sezione FAQ) progettata per abbassare le difese cognitive della vittima.
2. **Meccanismo di Innesco (Trigger):** Il click sul pulsante primario di voto (`.button-vote`) non esegue un invio dati. Invece, fa apparire un elemento DOM nascosto (`#warning-popup`) mascherato da verifica di sicurezza. Il vero attacco si materializza all'interno di questo pop-up.
3. **Traffico Anomalo e Redirect:** Durante l'esplorazione, la pagina tenta di caricare risorse grafiche da domini remoti russi (es. `allwebs.ru`). Il completamento dell'interazione forza un redirect verso il vero server di attacco: `https://winnerclose.pro/login/code2`.

## 5. Exploitation: L'Infrastruttura AITM (Fase 2)


L'analisi del secondo stage (`/login/code2`) ha esposto l'architettura **AITM (Adversary-in-the-Middle)**. Le evidenze di rete dimostrano l'uso di comunicazioni asincrone:
* **Protocollo WebSocket:** Il caricamento di `socket.io.js` e le transazioni Engine.IO (richieste XHR con payload microscopici da 1-2 byte) confermano l'instaurazione di un tunnel di comunicazione bidirezionale e persistente (Keep-Alive) tra la vittima e il server di Comando e Controllo (C2).

### 5.1. Decostruzione del Payload Core (`number.js`)
L'estrazione del file `number.js` (7 KB) ha fornito il codice sorgente della logica malevola. Il reverse engineering ha identificato tre funzioni critiche:
1. **Esfiltrazione Asincrona:** L'input della vittima (numero telefonico) viene purificato (`\D/g`) e trasmesso al C2 tramite WebSocket (`socket.emit("start_number")`) rigorosamente solo quando il tunnel è stabile.
2. **Autorizzazione Illecita:** Il C2 remoto, operando come client headless, genera l'OTP a 8 caratteri richiesto da WhatsApp e lo ritrasmette al DOM della vittima (`socket.on("code")`). L'inserimento manuale da parte della vittima completa l'autenticazione remota.
3. **OpSec (Dwell Time):** Un timer chiude il socket dopo esattamente 5 minuti (`setTimeout(function() { socket.close(); ... }, 5 * 60 * 1000)`), imitando il vero timeout di sicurezza di WhatsApp Web per limitare l'impronta di rete del C2.

### 5.2. Telemetria dell'Analista e Difese Anti-Analysis (Evasione)
La vera sofisticazione del kit emerge dalle sue difese attive:
* **Geo-Fencing e Fingerprinting:** Lo script esegue una chiamata API verso `ipapi.co/json/`. Oltre a pre-compilare dinamicamente il prefisso nazionale in base alla risposta JSON (es. `+39` per l'Italia), il C2 incamera i dati dell'Autonomous System Number (ASN).
* **Browser DoS (Denial of Service):** Se l'ASN rilevato appartiene a un Datacenter, a un nodo Tor o a un vendor di sicurezza (es. `AS212238 - Datacamp Limited`), l'IP viene classificato come *traffico sintetico*. In risposta, il C2 emette l'evento `surprise` via socket. Questo innesca la generazione simultanea di 1.000 Web Workers sul browser dell'analista, eseguendo cicli infiniti di pesanti calcoli matematici. Il risultato è l'esaurimento istantaneo della CPU (100%) e il crash della sandbox di analisi.

## 6. Post-Exploitation e Valutazione del Rischio
Il furto del token di sessione conferisce all'attaccante privilegi identici a quelli dell'utente legittimo sull'interfaccia web.
* **Impatto Logico Primario:** Data harvesting dallo storico chat e allegati, Business Messaging Compromise (impersonificazione in gruppi aziendali), propagazione laterale del phishing e offuscamento tattico (archiviazione silente delle chat compromesse).
* **Rischio di Compromissione Endpoint:** Sebbene il token rubato non fornisca privilegi di esecuzione sul sistema operativo locale (RCE), l'account WhatsApp dirottato funge da formidabile Vettore di Delivery. L'inoltro di artefatti eseguibili mascherati, se scaricati ed eseguiti da contatti fidati (o dalla vittima stessa su una workstation aziendale), garantisce all'avversario un Accesso Iniziale (Initial Access) alla rete interna.

**Sintesi:** La superficie di attacco tecnica si limita al servizio di messaggistica, ma la superficie di attacco logica si espande a qualsiasi dispositivo su cui i contatti della vittima scaricheranno i payload dell'attaccante.
