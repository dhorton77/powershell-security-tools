# MITRE ATT&CK Purple Team Lab Report

**Date:** 12 May 2026  
**Lab Environment:** VMware vSphere with IPFire firewall, Kali Linux Purple, Windows 10, Wazuh  
**Objective:** Execute realistic attack chain using MITRE ATT&CK techniques; map defensive controls and develop detection rules

---

## Executive Summary

This purple team exercise simulated a multi-stage attack against a Windows 10 target using Kali Linux Purple. The attack chain demonstrates real-world adversary techniques mapped to the MITRE ATT&CK framework, spanning reconnaissance, lateral movement, and credential access. Network traffic was captured and analyzed to develop actionable detection rules for Wazuh/Splunk.

**Attack Chain Techniques Executed:**
- T1018 - Remote System Discovery
- T1087.004 - Account Discovery (Domain Account)
- T1040 - Network Sniffing
- T1557.002 - Adversary-in-the-Middle: NTLM Relay
- T1021.002 - Lateral Movement: Windows Admin Shares

---

## Lab Architecture

### Network Setup

```
Orange Zone (192.168.243.0/24)
├── Kali Linux Purple: 192.168.243.130 (Attacker)
└── Windows 10 Target: 192.168.243.129 (Victim)

Green Zone (192.168.1.0/24)
├── Wazuh Manager: 192.168.1.20
└── Splunk Indexer: 192.168.1.x

Monitoring
├── Wireshark: Captured on Windows 10
├── tcpdump: Optional, Kali side
└── PCAP: mitre_attack_chain.pcapng
```

---

## Attack Chain Execution

### Phase 1: Reconnaissance (T1018 - Remote System Discovery)

**Objective:** Discover active hosts and open services on the network

**Technique:** Network scanning with Nmap

```bash
# Full port scan with service detection
nmap -sV -p- 192.168.243.129

# SMB-specific enumeration
nmap -sV --script smb-enum-shares.nse -p 445 192.168.243.129
```

**MITRE ATT&CK Mapping:**
- **Technique:** T1018 - Remote System Discovery
- **Tactic:** Reconnaissance
- **Sub-technique:** Active scanning, service enumeration

**Results Captured:**

| Port | Service | Version | Status |
|------|---------|---------|--------|
| 135 | msrpc | Microsoft Windows RPC | Open |
| 139 | netbios-ssn | Microsoft Windows NetBIOS | Open |
| 445 | microsoft-ds | SMB | Open |
| 5040 | unknown | - | Open |
| 49664-49670 | msrpc | Microsoft Windows RPC (High-numbered) | Open |

**Network IOC:**
- Target: 192.168.243.129
- Attacker: 192.168.243.130
- Scan type: TCP connect, service enumeration
- Protocols: TCP/445 (SMB), TCP/139 (NetBIOS), TCP/135 (RPC)

---

### Phase 2: Account Discovery (T1087.004 - Domain Account)

**Objective:** Enumerate user accounts and shares on the target

**Technique:** SMB enumeration using enum4linux

```bash
enum4linux -a 192.168.243.129
```

**MITRE ATT&CK Mapping:**
- **Technique:** T1087.004 - Account Discovery (Domain Account)
- **Tactic:** Discovery
- **Description:** Enumerated local and domain user accounts via SMB

**Results Captured:**

```
Known Usernames: administrator, guest, krbgt, domain admins
Workgroup: WORKGROUP (not domain-joined)
Workstation: WINDOWS-10-TEST
NetBIOS Names: Active
SMB Services: File Server Service, Workstation Service
```

**Network IOC:**
- Port 445/TCP (SMB enumeration traffic)
- Port 139/TCP (NetBIOS session)
- SMB dialect negotiation
- Account enumeration queries

---

### Phase 3: Network Sniffing & Credential Access (T1040 + T1557.002)

**Objective:** Capture NTLM credentials and relay them for authentication

**Techniques Used:**
1. **T1040 - Network Sniffing** (Responder)
2. **T1557.002 - Adversary-in-the-Middle: NTLM Relay** (ntlmrelayx)

**Attack Flow:**

```bash
# Terminal 1: Start Responder (capture NTLM hashes)
sudo responder -I eth0 -v

# Terminal 2: Set up NTLM relay to SMB target
impacket-ntlmrelayx -t smb://192.168.243.129

# Terminal 3: Trigger authentication from Windows 10
# (via UNC path: \\192.168.243.130\share)
```

**MITRE ATT&CK Mapping:**

| Technique | Tactic | Description |
|-----------|--------|-------------|
| T1040 | Collection | Responder captured broadcast traffic (NBNS, mDNS, LLMNR) |
| T1557.002 | Credential Access | Relayed NTLM authentication from Windows 10 to attacker-controlled SMB |
| T1021.002 | Lateral Movement | Exploited SMB to attempt code execution on target |

**Attack Details:**

- **Responder Activity:**
  - Listened on port 5355 (LLMNR), 137/UDP (NBNS), 5353 (mDNS)
  - Captured NTLM Type 2/3 messages from authentication attempts
  - Relayed credentials back to target SMB service

- **NTLM Relay Flow:**
  1. Victim (Windows 10) attempts to authenticate to attacker-controlled UNC path
  2. Responder intercepts authentication request
  3. ntlmrelayx relays NTLM credentials to victim's SMB server
  4. Gains authenticated access without knowing plaintext password

**Network IOC:**
- Source: 192.168.243.129 (Windows 10)
- Destination: 192.168.243.130 (Kali Purple)
- Protocols: SMB (445/TCP), LLMNR (5355/UDP), NBNS (137/UDP)
- Traffic Pattern: Authentication attempt → Relay → SMB connection

---

### Phase 4: Lateral Movement (T1021.002 - Windows Admin Shares)

**Objective:** Exploit SMB to gain remote code execution

**Technique:** SMB relay exploitation via impacket-ntlmrelayx

**MITRE ATT&CK Mapping:**
- **Technique:** T1021.002 - Remote Services: SMB/Windows Admin Shares
- **Tactic:** Lateral Movement
- **Description:** Relayed NTLM authentication to access administrative SMB shares

**Attack Sequence:**

```
1. Discovery (T1018) - Identify SMB services
2. Enumeration (T1087.004) - Find user accounts
3. Sniffing (T1040) - Capture network traffic
4. Relay (T1557.002) - NTLM man-in-the-middle
5. Lateral Movement (T1021.002) - Exploit authenticated SMB session
```

**Network IOC:**
- SMB signing not required (allows relay)
- NTLM authentication in cleartext equivalent (relayable)
- Admin shares accessible after relay: C$, IPC$, ADMIN$
- Persistence mechanism: Scheduled task or service creation (theoretical)

---

## Network Forensics - PCAP Analysis

### Captured Traffic Summary

**File:** `mitre_attack_chain.pcapng` (captured via Wireshark on Windows 10)

**Key Observations:**

| Phase | Protocol | Source | Destination | Port | Count |
|-------|----------|--------|-------------|------|-------|
| Discovery | TCP | 192.168.243.130 | 192.168.243.129 | Multiple | 65,524 closed TCP ports |
| Discovery | TCP | 192.168.243.130 | 192.168.243.129 | 445 | SMB SYN-ACK |
| Enumeration | SMB | 192.168.243.130 | 192.168.243.129 | 445 | Share enumeration, user queries |
| Sniffing | UDP | 192.168.243.129 | 255.255.255.255 | 137 | NetBIOS broadcasts |
| Relay | TCP | 192.168.243.129 | 192.168.243.130 | 445 | NTLM authentication relay |

### Traffic Patterns Indicating Attack

1. **Rapid TCP scanning** - Multiple connection attempts in seconds
2. **SMB share enumeration** - Queries for IPC$, ADMIN$, C$
3. **NTLM Type messages** - Authentication protocol in cleartext
4. **Relay indicators** - Same credentials relayed back to victim
5. **Failed admin access attempts** - 0xC0000005 (Access Denied) in SMB responses

---

## Detection Rules

### Wazuh Detection Rules

#### Rule 1: SMB Network Scanning (T1018)

```xml
<rule id="100001" level="6">
  <if_sid>5710</if_sid>
  <description>Possible SMB network scanning detected</description>
  <mitre>
    <id>T1018</id>
  </mitre>
</rule>

<rule id="100002" level="7">
  <if_sid>100001</if_sid>
  <status>^error</status>
  <field name="dstport">445</field>
  <field name="action">connection_refused</field>
  <description>Multiple failed SMB connections - possible port scan</description>
  <threshold frequency="10" timeframe="60">
    <same_source_ip />
  </threshold>
</rule>
```

#### Rule 2: SMB Enumeration (T1087.004)

```xml
<rule id="100010" level="6">
  <if_sid>5714</if_sid>
  <description>SMB share enumeration attempt detected</description>
  <mitre>
    <id>T1087.004</id>
  </mitre>
</rule>

<rule id="100011" level="7">
  <field name="dstport">445</field>
  <field name="command">enum</field>
  <description>Lateral movement: SMB enumeration targeting administrative shares</description>
</rule>
```

#### Rule 3: NTLM Relay Attack (T1557.002 + T1040)

```xml
<rule id="100020" level="8">
  <if_sid>5746</if_sid>
  <description>NTLM relay attack detected - credential interception</description>
  <mitre>
    <id>T1040</id>
    <id>T1557.002</id>
  </mitre>
</rule>

<rule id="100021" level="8">
  <field name="protocol">smb</field>
  <field name="ntlm_type">3</field>
  <description>NTLM Type 3 (response) detected - possible NTLM relay in progress</description>
  <threshold frequency="5" timeframe="30">
    <same_source_ip />
  </threshold>
</rule>
```

#### Rule 4: Lateral Movement via SMB (T1021.002)

```xml
<rule id="100030" level="8">
  <if_sid>5760</if_sid>
  <description>Lateral movement via SMB admin shares detected</description>
  <mitre>
    <id>T1021.002</id>
  </mitre>
</rule>

<rule id="100031" level="8">
  <field name="dstport">445</field>
  <field name="share">ADMIN\$|C\$|IPC\$</field>
  <description>Successful connection to administrative shares - possible lateral movement</description>
</rule>
```

### Splunk Detection Queries

#### Query 1: Detect Port Scanning (T1018)

```spl
sourcetype=network protocol=tcp action=connection_refused 
dstport=445 
| stats count by src_ip, dst_ip 
| where count > 50
```

#### Query 2: Detect SMB Enumeration (T1087.004)

```spl
sourcetype=smb action=enum 
| stats count by src_ip, dst_ip, share_name 
| where count > 10
```

#### Query 3: Detect NTLM Relay (T1557.002)

```spl
sourcetype=network protocol=smb ntlm_type=3 
| stats count, values(src_ip) as attackers by dst_ip 
| where count > 5
```

#### Query 4: Detect Lateral Movement (T1021.002)

```spl
sourcetype=smb share IN (ADMIN$, C$, IPC$) action=success 
| stats count by src_ip, dst_ip, user 
| where count > 3
```

---

## Detection Strategy Summary

| Technique | Detection Layer | Signal | Severity |
|-----------|-----------------|--------|----------|
| T1018 | Network (IDS) | Rapid TCP connections to port 445 | MEDIUM |
| T1087.004 | Network (SMB logs) | Share enumeration queries | MEDIUM |
| T1040 | Network (Traffic analysis) | Broadcast/LLMNR traffic patterns | MEDIUM |
| T1557.002 | Network (NTLM analysis) | Type 2/3 messages from relay | HIGH |
| T1021.002 | Host + Network | Admin share access + SMB signing bypass | CRITICAL |

---

## Real-World Applicability

### Why This Attack Works

1. **SMB Signing Not Required** - Windows allows relay if signing is disabled
2. **NTLM Authentication** - Older protocol vulnerable to relay (Kerberos is safer)
3. **Broadcast Protocols** - LLMNR/NBNS allow attacker to intercept auth requests
4. **Admin Shares** - C$, ADMIN$ are enabled by default on Windows

### Enterprise Defense

**Mitigations:**
- ✅ Enable SMB signing on all machines
- ✅ Enforce Kerberos over NTLM where possible
- ✅ Disable LLMNR/NBNS or implement DMVS (DNS Devolutions MVPS)
- ✅ Deploy EDR to detect relay patterns
- ✅ Implement conditional access policies for SMB connections
- ✅ Monitor failed authentication patterns across network

---

## Lab Outcomes

✅ **MITRE ATT&CK Mapping:** 5 techniques executed and documented  
✅ **Network Forensics:** Full PCAP captured showing attack chain  
✅ **Detection Engineering:** Wazuh + Splunk rules developed for each technique  
✅ **Purple Team Methodology:** Demonstrated offensive execution + defensive detection  
✅ **Documentation:** Technique IDs, network IOCs, and remediation paths

---

## Appendix: Lab Commands

### Reconnaissance Phase

```bash
# Full nmap scan
nmap -sV -p- 192.168.243.129

# SMB-specific enumeration
nmap -sV --script smb-enum-shares.nse -p 445 192.168.243.129

# enum4linux full enumeration
enum4linux -a 192.168.243.129
```

### Lateral Movement Phase

```bash
# Terminal 1: Start Responder
sudo responder -I eth0 -v

# Terminal 2: Set up NTLM relay
impacket-ntlmrelayx -t smb://192.168.243.129

# Terminal 3 (on Windows 10): Trigger authentication
\\192.168.243.130\share
```

### Network Capture

```bash
# Wireshark (GUI on Windows 10)
# - Select Ethernet0
# - Click Start Capture
# - Export as: File > Export Packets As > mitre_attack_chain.pcapng

# tcpdump (alternative on Kali)
sudo tcpdump -i eth0 -w mitre_attack_chain.pcap host 192.168.243.129
```

---

## References

- MITRE ATT&CK Framework: https://attack.mitre.org/
- T1018 - Remote System Discovery: https://attack.mitre.org/techniques/T1018/
- T1087.004 - Account Discovery: https://attack.mitre.org/techniques/T1087/004/
- T1040 - Network Sniffing: https://attack.mitre.org/techniques/T1040/
- T1557.002 - NTLM Relay: https://attack.mitre.org/techniques/T1557/002/
- T1021.002 - SMB/Windows Admin Shares: https://attack.mitre.org/techniques/T1021/002/
- Impacket ntlmrelayx: https://github.com/fortra/impacket
- Responder: https://github.com/lgandx/Responder
- Wazuh Documentation: https://documentation.wazuh.com/

---

**Lab Completed By:** David Horton  
**Environment:** VMware Home Lab with Kali Linux Purple, Windows 10  
**Duration:** ~3 hours (including troubleshooting and analysis)  
**GitHub:** github.com/dhorton77/security-engineering-portfolio
