# Troubleshoot exploit protection mitigations

1. Remove Windows Defender Exploit Protection mitigations

Run remove-wdep-mitigations.ps1.

```
PowerShell.exe -ExecutionPolicy Bypass -File remove-wdep-mitigations.ps1
```

2. Import / restore default mitigations

```
Set-ProcessMitigation -PolicyFilePath default_mitigations.xml
Set-ProcessMitigation -System -Reset
```

**Source**

https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/microsoft-365/security/defender-endpoint/troubleshoot-exploit-protection-mitigations.md