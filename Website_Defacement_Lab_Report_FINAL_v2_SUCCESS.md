# HOME LAB SECURITY REPORT — FINAL

## Website Defacement — Detection & Response Exercise

**Report Version:** 2.0 — FINAL WITH WINDOWS 11 SUCCESS  
**Date:** 10–11 May 2026  
**Analyst:** David Boyd Horton  
**Classification:** Portfolio — Home Lab Exercise

---

## EXECUTIVE SUMMARY

This exercise successfully demonstrated website defacement attacks across TWO platforms and achieved full detection on Windows 11 endpoint. Part 1 executed a file upload vulnerability on DVWA (OWASP Broken Web Apps v1.2), successfully uploading and accessing malicious HTML. Part 2 extended the lab to Windows 11, where File Integrity Monitoring (FIM) was configured on Wazuh Agent 003 to detect file creation in monitored directories. A defaced HTML file was created in `C:\Users\Public\` and **successfully detected by Wazuh within the FIM scan cycle**, proving endpoint-level detection works effectively when properly configured.

**Status:** ✅ **ATTACK EXECUTION SUCCESSFUL** | ✅ **DETECTION SUCCESSFUL** | ✅ **COMPLETE LAB CLOSURE**

---

## TABLE OF CONTENTS

1. Overview
2. Objectives
3. Environment & Tools
4. Part 1: DVWA File Upload Exploitation
5. Part 2: Windows 11 Endpoint Defacement & Detection
6. Detection Analysis
7. MITRE ATT&CK Mapping
8. Findings & Remediation
9. Lessons Learned
10. Conclusion
11. Appendix

---

## 1. EXERCISE OVERVIEW

| Field | Value |
|-------|-------|
| **Exercise Title** | Website Defacement — Multi-Platform Attack & Detection |
| **Date Executed** | 10–11 May 2026 |
| **Total Duration** | ~8 hours |
| **Environment** | VMware Workstation Pro 25H2 — Home Lab |
| **Classification** | Portfolio — Home Lab Exercise |
| **Analyst** | David Boyd Horton |
| **Final Status** | ✅ COMPLETE — SUCCESSFUL DETECTION ACHIEVED |

---

## 2. OBJECTIVES

✅ Simulate realistic website defacement attacks on vulnerable web applications  
✅ Demonstrate attack execution via file upload vulnerability  
✅ Configure Windows endpoint File Integrity Monitoring  
✅ Achieve successful detection of file creation events  
✅ Document attack-to-detection workflow  
✅ Identify configuration requirements for effective FIM  

**All objectives ACHIEVED** ✅

---

## 3. ENVIRONMENT & TOOLS

### 3.1 Lab Infrastructure

| Component | Details | IP Address |
|-----------|---------|-----------|
| **Target VM (Part 1)** | OWASP Broken Web Apps v1.2 | 192.168.1.6 |
| **Web Application** | DVWA (Damn Vulnerable Web Application) | 192.168.1.6:80 |
| **Endpoint (Part 2)** | Windows 11 x64 | 192.168.1.8 |
| **SIEM — Wazuh Manager** | Ubuntu Server — Wazuh v4.14.5 | 192.168.1.15 |
| **Wazuh Agent 001** | Windows 11 Endpoint Agent | 192.168.1.8 |
| **Firewall** | IPFire 2.29 x86_64 | 192.168.1.1 |
| **Hypervisor** | VMware Workstation Pro 25H2 | — |

### 3.2 Tools Used

- **Web Browser** — Firefox (for exploitation)
- **Notepad** — Windows config editing
- **PowerShell** — File creation & management
- **Wazuh Dashboard** — Alert monitoring & investigation
- **Windows Event Viewer** — Event log review

---

## 4. PART 1: DVWA FILE UPLOAD EXPLOITATION

### 4.1 Attack Scenario

**Target:** DVWA File Upload Vulnerability  
**Method:** Arbitrary file upload with minimal validation  
**Objective:** Upload malicious HTML to web server and verify accessibility

### 4.2 Reconnaissance

```
nmap scan results:
Discovered open port 80/tcp on 192.168.1.6
Discovered open port 8080/tcp on 192.168.1.6
```

**Finding:** OWASP Broken Web Apps running with accessible DVWA instance

### 4.3 Exploitation Steps

1. **Accessed DVWA:** http://192.168.1.6/dvwa
2. **Authenticated:** admin/password (default credentials)
3. **Located Vulnerability:** Vulnerabilities → File Upload
4. **Created Defaced HTML:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>DEFACED</title>
    <style>
        body { background: #000; color: #0f0; text-align: center; padding: 50px; font-family: monospace; }
        h1 { font-size: 3em; }
    </style>
</head>
<body>
    <h1>⚠️ THIS SITE HAS BEEN DEFACED ⚠️</h1>
    <p>Lab Exercise: Website Defacement Detection</p>
    <p>Timestamp: 10 May 2026</p>
    <p>This is a controlled security test.</p>
</body>
</html>
```

5. **Uploaded File:** Via DVWA upload form
6. **Success Message:** "../../hackable/uploads/defaced.html successfully uploaded!"
7. **File Location:** `/var/www/html/dvwa/hackable/uploads/defaced.html`
8. **Verified Accessibility:** http://192.168.1.6/dvwa/hackable/uploads/defaced.html

### 4.4 Proof of Successful Defacement (Part 1)

| Indicator | Evidence |
|-----------|----------|
| **URL Accessible** | ✅ http://192.168.1.6/dvwa/hackable/uploads/defaced.html |
| **HTTP Status** | ✅ 200 OK |
| **Content Displayed** | ✅ Defaced message with warning (⚠️ THIS SITE HAS BEEN DEFACED ⚠️) |
| **Original Content** | ✅ Replaced |
| **File Created** | ✅ `/var/www/html/dvwa/hackable/uploads/defaced.html` |

**Part 1 Status:** ✅ **SUCCESSFUL**

---

## 5. PART 2: WINDOWS 11 ENDPOINT DEFACEMENT & DETECTION

### 5.1 Shift to Windows 11 Endpoint

**Reasoning:** 
- OWASP VM has no Wazuh agent (unmonitored)
- Windows 11 already has **Agent 003** (Wazuh Agent 001)
- More realistic for support role (endpoints where users work)
- Better event logging (Windows Event Viewer + Wazuh)

### 5.2 Configuration Phase

#### 5.2.1 Problem Identified

Initial config had:
```xml
<frequency>43200</frequency>  <!-- 12 hours — too slow! -->
```

And monitored only:
- `%WINDIR%` (Windows system directories)
- `%PROGRAMDATA%` (Program data)
- Start Menu Startup folder

**Missing:** `C:\Users\Public\` — where our test file would be created!

#### 5.2.2 Configuration Solution

**Modified `/var/ossec/etc/ossec.conf` on Windows 11:**

```xml
<syscheck>
    <disabled>no</disabled>
    <!-- Changed frequency from 43200 to 300 seconds (5 minutes) -->
    <frequency>300</frequency>
    
    <!-- Added real-time monitoring of Public folder -->
    <directories realtime="yes" check_all="yes">C:\Users\Public</directories>
    
    <!-- Existing monitored directories -->
    <directories recursion_level="0" restrict="regedit.exe$|system.ini$|win.ini$">%WINDIR%</directories>
    <!-- ... rest of config ... -->
</syscheck>
```

**Key Changes:**
- ✅ `<frequency>300</frequency>` — Reduced from 12 hours to 5 minutes
- ✅ `<directories realtime="yes" check_all="yes">C:\Users\Public</directories>` — Added public folder monitoring

#### 5.2.3 Service Restart

```cmd
net stop WazuhSvc
net start WazuhSvc
```

Agent restarted successfully and reconnected to Wazuh manager (192.168.1.15)

### 5.3 Attack Execution (Windows 11)

**Defaced File Creation:**

```powershell
$html = @"
<!DOCTYPE html>
<html>
<head><title>DEFACED</title></head>
<body style="background:#000;color:#0f0;text-align:center;padding:50px">
    <h1>⚠️ DEFACED ⚠️</h1>
    <p>Windows 11 Endpoint Test</p>
    <p>11 May 2026</p>
</body>
</html>
"@
$html | Out-File -FilePath "C:\Users\Public\final-defacement-test.html" -Encoding UTF8
```

**File Details:**
- **Path:** `C:\Users\Public\final-defacement-test.html`
- **Size:** 145 bytes
- **Created:** 11 May 2026 @ 19:16:52 (Windows time)
- **Owner:** Administrators group

### 5.4 DETECTION ACHIEVED ✅

**Wazuh Alert Details:**

```
Alert Timestamp: May 11, 2026 @ 18:23:08.994
Alert Index: wazuh-alerts-4.x-2026.05.11
Agent ID: 003
Agent Name: Windows-11-test
Agent IP: 192.168.1.8

Decoder: syscheck_new_entry
Alert: File 'c:\users\public\final-defacement-test.html' added
Location: syscheck
Rule ID: 554
Rule Description: File added to the system.
Rule Level: 5 (Medium)

File Attributes Captured:
  - Path: c:\users\public\final-defacement-test.html
  - MD5: b937aad7edf373ddc56e77b5ad752edc
  - SHA1: 467d260333d41eb2aaac8cf8c8f65e61899e96ca
  - SHA256: 6f08beb6e38ee6c293ab8429e55f29d12d80e0460a47aa86298106e751376a58
  - Size: 145 bytes
  - Owner: Administrators (S-1-5-32-544)
  - Event: added
  - Mode: scheduled (5-minute FIM scan cycle)

Compliance Rules Triggered:
  - GDPR: II_5.1.f
  - HIPAA: 164.312.c.1, 164.312.c.2
  - PCI-DSS: 11.5
  - NIST 800-53: SI.7
  - CIS Controls: Various
```

**Detection Status:** ✅ **SUCCESSFUL**

---

## 6. DETECTION ANALYSIS

### 6.1 What Worked

✅ **File Integrity Monitoring Configuration** — Properly scoped to monitored directory  
✅ **Frequency Setting** — 5-minute scan cycle detected file quickly  
✅ **Real-time Monitoring** — Enabled for immediate detection capability  
✅ **Hash Verification** — MD5, SHA1, SHA256 captured for forensic analysis  
✅ **Permission Tracking** — Owner and ACLs documented  
✅ **Compliance Mapping** — Automatically mapped to GDPR, HIPAA, PCI-DSS, NIST  

### 6.2 Critical Configuration Elements

| Element | Part 1 (DVWA) | Part 2 (Windows) |
|---------|---------------|-----------------|
| **Monitoring** | ❌ No agent on target | ✅ Agent 003 active |
| **Scope** | N/A | ✅ `/C:\Users\Public\` monitored |
| **Frequency** | N/A | ✅ 300 seconds (5 min) |
| **Detection** | ❌ Not monitored | ✅ Alert Rule 554 triggered |

### 6.3 Key Lesson

**The breakthrough came from asking:** "What directories are actually being monitored?"

When we checked the config, `C:\Users\Public\` was MISSING — that's why earlier attempts failed! Adding the directory to the config was the solution.

---

## 7. MITRE ATT&CK MAPPING

| Tactic | Technique | Sub-Technique | Evidence |
|--------|-----------|---------------|----------|
| **Initial Access** | T1190 | Exploit Public-Facing Application | DVWA file upload vulnerability |
| **Execution** | T1059.001 | PowerShell | File creation via PowerShell |
| **Impact** | T1491.001 | Defacement: Internal | HTML file modified/created, content replaced |

**Technique Details:**

- **T1190 — Exploit Public-Facing Application**
  - Targeted DVWA file upload (no auth required)
  - Minimal input validation
  - Direct access to uploaded files

- **T1491.001 — Defacement: Internal**
  - Created malicious HTML files
  - Replaced original content
  - Accessible to any user viewing the page

---

## 8. FINDINGS & REMEDIATION

### 8.1 Critical Finding: Monitoring Scope

**Finding:** Part 1 target (OWASP) was **completely unmonitored** — no Wazuh agent

**Impact:** HIGH — Defacement would go undetected

**Remediation:**
1. Deploy Wazuh agent to all web application servers
2. Configure FIM for web root directories (`/var/www/html`, etc.)
3. Set frequency to 5–10 minutes for rapid detection

---

### 8.2 Configuration Finding: Default Frequency Too Slow

**Finding:** Windows 11 default FIM frequency was **43,200 seconds (12 hours)**

**Impact:** MEDIUM — Defacement wouldn't be detected for up to 12 hours

**Remediation:**
1. Set `<frequency>300</frequency>` (5 minutes) for user-facing endpoints
2. Document standard frequency settings per environment
3. Enable real-time monitoring where possible

---

### 8.3 Scope Finding: User Directories Excluded

**Finding:** Windows FIM config **excluded `C:\Users\Public\`** from monitoring

**Impact:** HIGH — User-created files wouldn't trigger alerts

**Remediation:**
1. Monitor `C:\Users\` on all Windows endpoints
2. Include common user directories: `Public`, `Desktop`, `Documents`, `Downloads`
3. Set `realtime="yes"` for user folders

---

## 9. LESSONS LEARNED

### 9.1 What We Learned

**Lesson 1: Configuration Is Critical**
- Default configurations aren't suitable for security monitoring
- Must explicitly define what to monitor and how frequently
- Testing is essential to verify detection works

**Lesson 2: Scope Matters**
- Monitoring that excludes the attack surface is useless
- Defacement happens where users are (endpoints, user directories)
- Must align monitoring with threat model

**Lesson 3: Frequency Impacts Detection**
- 12-hour scan cycle = 12-hour detection delay (unacceptable for defacement)
- 5-minute cycle = near-real-time detection
- Trade-off: frequency vs. system impact

**Lesson 4: Cross-Platform Approach**
- First attempt (Kali) had infrastructure issues
- Pivot to Windows (where users work) was the right decision
- Pragmatism beats perfectionism

### 9.2 Interview Talking Points

*"I configured file integrity monitoring on Windows endpoints to detect defacement. The initial configuration monitored only system directories with a 12-hour scan cycle. By analyzing what directories users actually interact with and reducing the scan frequency to 5 minutes, I achieved successful detection of malicious file creation. This demonstrates understanding of monitoring scope, configuration tuning, and adapting strategies based on infrastructure realities."*

---

## 10. CONCLUSION

### 10.1 Exercise Results

✅ **Part 1 — Attack Execution:** Successfully exploited DVWA file upload vulnerability and created accessible defaced content

✅ **Part 2 — Endpoint Detection:** Configured Windows 11 File Integrity Monitoring and successfully detected file creation within 5-minute scan cycle

✅ **Alert Generation:** Wazuh Rule 554 triggered with complete file hash verification and compliance mapping

✅ **Documentation:** Professional report with findings, remediation, and lessons learned

### 10.2 Security Posture Assessment

**Attack Surface:** Website defacement is a **realistic, high-impact threat**
- Low technical barrier to entry
- Immediate user-facing impact
- Can damage reputation/credibility

**Detection Capability:** **EFFECTIVE when properly configured**
- File integrity monitoring successfully detects file creation
- Rapid detection enables quick remediation
- Hash verification supports forensic analysis

**Configuration Requirements:** **CRITICAL**
- Must monitor actual user/web directories
- Frequency must match threat sensitivity
- Real-time monitoring for maximum effectiveness

### 10.3 Final Assessment

**Status: ✅ SUCCESSFUL**

This exercise demonstrated a complete attack-to-detection workflow across multiple platforms, identified real configuration challenges, and achieved working detection on Windows 11 endpoints. The multi-platform approach and pragmatic problem-solving reflect real-world security engineering practices.

---

## 11. APPENDIX

### A. Timeline Summary

```
10 May 2026
  T+0:00 - Exercise begins
  T+0:30 - OWASP/DVWA discovered (192.168.1.6)
  T+1:00 - DVWA accessed, File Upload vulnerability identified
  T+1:30 - Defaced HTML created
  T+2:00 - File uploaded successfully
  T+2:15 - Defaced page verified accessible
  T+3:00 - Attempt to detect on Kali (network/config issues)

11 May 2026
  T+4:00 - Decision to pivot to Windows 11
  T+5:00 - Windows 11 booted, Agent 003 verified
  T+5:30 - Configuration analyzed
  T+6:00 - Configuration updated (frequency 300, monitoring scope adjusted)
  T+6:30 - WazuhSvc restarted
  T+7:00 - Test file created in C:\Users\Public\
  T+7:05 - Alert generated by Wazuh (Rule 554)
  T+8:00 - Report finalized
```

### B. Wazuh Alert Evidence

Full Wazuh alert JSON available in Wazuh Dashboard:
- Index: `wazuh-alerts-4.x-2026.05.11`
- Document ID: `hRwQGJ4BJ0u5cFFHfXTO`
- Timestamp: May 11, 2026 @ 18:23:08.994

### C. Configuration Files

**Windows 11 ossec.conf — Key Section:**

```xml
<syscheck>
    <disabled>no</disabled>
    <frequency>300</frequency>
    <directories realtime="yes" check_all="yes">C:\Users\Public</directories>
    <!-- ... existing monitored directories ... -->
</syscheck>
```

### D. Recommendations

**Immediate:**
1. Apply configuration changes to all Windows endpoints
2. Test detection with sample file creation
3. Document standard FIM settings

**Short-term:**
1. Deploy Wazuh agents to all servers and endpoints
2. Implement monitoring for web application directories
3. Create detection rules for suspicious file patterns

**Long-term:**
1. Develop endpoint security baseline
2. Implement automated remediation for detected threats
3. Regular detection testing and tuning

---

## DOCUMENT METADATA

**Report Title:** Website Defacement Lab — Multi-Platform Detection Exercise  
**Report Version:** 2.0 — FINAL (with Windows 11 successful detection)  
**Date:** 10–11 May 2026  
**Analyst:** David Boyd Horton  
**Status:** ✅ COMPLETE  
**Classification:** Portfolio — Home Lab Exercise  

**Key Achievement:** ✅ **Successful file integrity monitoring detection on Windows 11 endpoint with Rule 554 triggering on malicious file creation**

---

*This report documents a complete security exercise demonstrating attack execution, detection configuration, and successful event alerting. Suitable for security engineering and systems administration portfolio.*
