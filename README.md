# 🛡️ PowerShell Security & Infrastructure Tools

Welcome to the **PowerShell Security & Infrastructure Tools** repository. This project contains a comprehensive suite of custom PowerShell scripts designed for active infrastructure monitoring, advanced threat hunting, forensic triage, and Indicator of Compromise (IOC) simulation. 

All scripts are located in the /Scripts/ directory.

## 🗂️ Script Categories & Capabilities

### 1. 📊 Infrastructure & Event Monitoring (GUI Tools)
These tools feature custom Windows Forms graphical interfaces to simplify remote management and real-time monitoring.
* **vent monitoring.ps1**: A continuous infrastructure monitor that polls process loads, system memory (CIM), service integrity, and security event logs (Event IDs 4625 & 4688) over WinRM.
* **PowerShell Remote Session Manager.ps1**: A GUI utility for securely connecting to and managing remote Windows hosts, executing commands, and verifying TrustedHosts configurations.
* **irst system monitor.ps1**: A lightweight, GUI-based ping sweeper for rapid network node status checks.

### 2. 🎯 Threat Simulation & IOC Generation
Scripts designed for safe execution in lab environments to simulate adversarial behavior and validate SIEM/logging configurations.
* **create-adiocs.ps1**: Simulates Active Directory reconnaissance, lateral movement, registry/scheduled task persistence, and mock NTDS extraction.
* **create-eventlogiocs.ps1**: Generates suspicious Event Tracing logs by simulating brute-force logins, privilege escalation, and suspicious PowerShell execution.
* **create-regexiocs.ps1**: Generates simulated log files injected with malicious IP addresses, SQL injection attempts, and encoded command strings for regex parsing practice.

### 3. 🔍 Threat Hunting & Detection
A robust set of threat hunting scripts designed to parse logs, memory, and directories for signs of compromise.
* **detect_AD_iocsv1.ps1**: An extensive script that queries event logs to detect AD enumeration, WinRM lateral movement, suspicious scheduled tasks, LOLBins usage, and DCSync replication activity.
* **detect-filelessmalware.ps1**: Hunts for fileless malware indicators by identifying processes without backing files, suspicious registry run keys, and anomalous PowerShell scriptblocks.
* **detect-cloudiocs.ps1**: Leverages the Microsoft Graph API to audit privileged Entra ID (Azure AD) roles, evaluate conditional access bypasses, and hunt for dangerous OAuth consent grants.
* **detect-adsfile.ps1 & detect-adsfiles.ps1**: Scans target files and recursive directories to identify hidden Alternate Data Streams (ADS) often used to conceal malicious payloads.
* **detect-logiocs.ps1**: A streamlined event log parser hunting for critical security events (4625, 4688, 7045).
* **detect-regexiocs.ps1**: A regex-based parsing tool that scans unstructured log files for malicious IPs, commands, and SQL injection syntax.

### 4. 🕵️‍♂️ Forensics & Triage
* **Triage.ps1**: An automated incident response data collector. It aggregates native system information, utilizes Sysinternals tools (Autoruns, Handle, TCPVcon), and integrates with PowerForensics to extract MFTs, Amcache, and executable timelines.

---

### ⚠️ Disclaimer
**For Educational and Lab Use Only.** The simulation scripts in this repository (create-*) actively execute simulated adversarial techniques and generate artificial indicators of compromise. Do not run these scripts in a production environment without explicit authorization.
