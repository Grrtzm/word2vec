# This script is bases on Windows Powershell version 7.1
# Please note: if you get red text during execution, these are warnings, not errors.
$debug = 0 # 1 = Do not actually generate logfiles (takes too much time)
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue' # This eliminates the red text mentioned above. The difference between "real" errors (try/catch) and these are vague.

# Select which logs to use (select 1 of more):
$useApplicationLog = 1

function getLogs{
	Write-Host "`nFetching and parsing events from the Application event log."
	Write-Host "This might take 10 minutes or more...`n"

	# Create an empty file in advance. This prevents me from writing code to select which file i will use.
	Remove-Item '.\Application-Events-custom.csv'
	New-Item -Path '.\Application-Events-custom.csv' -ItemType File
	
	If($debug -eq 0){
		If($useApplicationLog -eq 1){
			Write-Host "Reading Application Event log...`n"
			try{
				Get-WinEvent -Path '.\Application.evtx' | ForEach-Object {
					$Values = $_.Properties | ForEach-Object { $_.Value }
					
					# return a new object with the required information
					[PSCustomObject]@{
						TimeCreated   = $_.TimeCreated.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
						EventRecordID = $_.RecordID
						EventID       = "System_"+$_.ID
						Level		  = $_.LevelDisplayName
						Provider	  = $_.ProviderName
						Message       = $_.Message
					}
				} | Export-Csv -Path '.\Application-Events-custom.csv' -Delimiter ',' -Encoding UTF8 -Force -NoTypeInformation
			}
			catch {
				Write-Host "An error has occurred:"
				Write-Host $_
			}
		}
	}
}

# Measure the elapsed time:
Measure-Command { getLogs | Out-Default}
