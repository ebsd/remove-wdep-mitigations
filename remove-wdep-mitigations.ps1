# source: https://github.com/MicrosoftDocs/microsoft-365-docs/blob/public/microsoft-365/security/defender-endpoint/troubleshoot-exploit-protection-mitigations.md

# Get log path
$logPath = "C:\ProgramData\disable-EP\Logs"
$logFile = "$logPath\$($myInvocation.MyCommand).log"

# Start logging
Start-Transcript $logFile
Write-Host "Logging to $logFile"

# Check if Admin-Privileges are available
function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

# Delete ExploitGuard ProcessMitigations for a given key in the registry. If no other settings exist under the specified key,
# the key is deleted as well
function Remove-ProcessMitigations([Object] $Key, [string] $Name) {
    Try {
        if ($Key.GetValue("MitigationOptions")) {
            Write-Host "Removing MitigationOptions for:      " $Name
            Remove-ItemProperty -Path $Key.PSPath -Name "MitigationOptions" -ErrorAction Stop;
        }
        if ($Key.GetValue("MitigationAuditOptions")) {
            Write-Host "Removing MitigationAuditOptions for: " $Name
            Remove-ItemProperty -Path $Key.PSPath -Name "MitigationAuditOptions" -ErrorAction Stop;
        }

        # Remove the FilterFullPath value if there is nothing else
        if (($Key.SubKeyCount -eq 0) -and ($Key.ValueCount -eq 1) -and ($Key.GetValue("FilterFullPath"))) {
            Remove-ItemProperty -Path $Key.PSPath -Name "FilterFullPath" -ErrorAction Stop;
        }

        # If the key is empty now, delete it
        if (($Key.SubKeyCount -eq 0) -and ($Key.ValueCount -eq 0)) {
            Write-Host "Removing empty Entry:                " $Name
            Remove-Item -Path $Key.PSPath -ErrorAction Stop
        }
    }
    Catch {
        Write-Host "ERROR:" $_.Exception.Message "- at ($MitigationItemName)"
    }
}

# Delete all ExploitGuard ProcessMitigations
function Remove-All-ProcessMitigations {
    if (!(Test-IsAdmin)) {
        throw "ERROR: No Administrator-Privileges detected!"; return
    }

    Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" | ForEach-Object {
        $MitigationItem = $_;
        $MitigationItemName = $MitigationItem.PSChildName

        Try {
            Remove-ProcessMitigations $MitigationItem $MitigationItemName

            # "UseFilter" indicate full path filters may be present
            if ($MitigationItem.GetValue("UseFilter")) {
                Get-ChildItem -Path $MitigationItem.PSPath | ForEach-Object {
                    $FullPathItem = $_
                    if ($FullPathItem.GetValue("FilterFullPath")) {
                        $Name = $MitigationItemName + "-" + $FullPathItem.GetValue("FilterFullPath")
                        Write-Host "Removing FullPathEntry:              " $Name
                        Remove-ProcessMitigations $FullPathItem $Name
                    }

                    # If there are no subkeys now, we can delete the "UseFilter" value
                    if ($MitigationItem.SubKeyCount -eq 0) {
                        Remove-ItemProperty -Path $MitigationItem.PSPath -Name "UseFilter" -ErrorAction Stop
                    }
                }
            }
            if (($MitigationItem.SubKeyCount -eq 0) -and ($MitigationItem.ValueCount -eq 0)) {
                Write-Host "Removing empty Entry:                " $MitigationItemName
                Remove-Item -Path $MitigationItem.PSPath -ErrorAction Stop
            }
        }
        Catch {
            Write-Host "ERROR:" $_.Exception.Message "- at ($MitigationItemName)"
        }
    }
}

# Delete all ExploitGuard System-wide Mitigations
function Remove-All-SystemMitigations {

    if (!(Test-IsAdmin)) {
        throw "ERROR: No Administrator-Privileges detected!"; return
    }

    $Kernel = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"

    Try {
        if ($Kernel.GetValue("MitigationOptions"))
            { Write-Host "Removing System MitigationOptions"
                Remove-ItemProperty -Path $Kernel.PSPath -Name "MitigationOptions" -ErrorAction Stop;
            }
        if ($Kernel.GetValue("MitigationAuditOptions"))
            { Write-Host "Removing System MitigationAuditOptions"
                Remove-ItemProperty -Path $Kernel.PSPath -Name "MitigationAuditOptions" -ErrorAction Stop;
            }
    } Catch {
        Write-Host "ERROR:" $_.Exception.Message "- System"
    }
}

# Select what you want to remove
Remove-All-ProcessMitigations
Remove-All-SystemMitigations

# Stop logging
Stop-Transcript