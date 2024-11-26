# Automating OOBE by downloading an answer file from the internet
# https://www.outsidethebox.ms/22491/#internet
# # # # # # # # # # # # # # # # # # # # ################

# # # # # # # # # # # # # # # # # # # # ################ 
# Pre-checks: if not in OOBE, exit out
# https://oofhours.com/2023/09/15/detecting-when-you-are-in-oobe/

$TypeDef = @" 
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
  
namespace Api
{
 public class Kernel32
 {
   [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
   public static extern int OOBEComplete(ref int bIsOOBEComplete);
 }
}
"@ 
Add-Type -TypeDefinition $TypeDef -Language CSharp
  
$IsOOBEComplete = $false
$hr = [Api.Kernel32]::OOBEComplete([ref] $IsOOBEComplete)
if ($IsOOBEComplete) {
  Write-Host "Not in OOBE, nothing to do."
  exit 0
}

# # # # # # # # # # # # # # # # # # # # ################ 
# Select URI based on user input
Write-Host "Select an answer file to use:" -ForegroundColor Cyan
Write-Host "1. Set Hostname (https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/autounattend-win11pro-setHostname.xml)"
Write-Host "2. For Sale (https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/autounattend-forsale.xml)"
Write-Host "3. Contractors (https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/MemsTechTips-Autounattend.xml)"
Write-Host "3. EMPTY ()"

$uri = ""
do {
    $choice = Read-Host "Enter the number of your choice (1, 2, or 3)"
    switch ($choice) {
        "1" { $uri = "https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/autounattend-win11pro-setHostname.xml"; break }
        "2" { $uri = "https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/autounattend-forsale.xml"; break }
        "3" { $uri = "https://raw.githubusercontent.com/ali2key/AutoDeploy/refs/heads/main/MemsTechTips-Autounattend.xml"; break }
        "4" { $uri = ""; break }      
        default { Write-Host "Invalid selection. Please choose 1, 2, or 3." -ForegroundColor Red }
    }
} while (-not $uri)  # Loop until $uri is set

Write-Host "Selected URI: $uri" -ForegroundColor Green

# # # # # # # # # # # # # # # # # # # # ################ 
# Download the answer file and point sysprep to it
##Write-Host "Your username and password will be: Admin/Admin" -ForegroundColor DarkGreen
$answer = "$env:temp\UnattendOOBE.xml"
(Invoke-RestMethod -Uri $uri).OuterXml | Out-File -FilePath $answer -Encoding utf8 -Force
foreach ($letter in $((Get-Volume).DriveLetter)) {
    if (Test-Path "$($letter):\Windows\System32\Sysprep\sysprep.exe") {
        Invoke-Expression "$($letter):\Windows\System32\Sysprep\sysprep.exe /reboot /oobe /unattend:$answer" 
        break
    }
}
