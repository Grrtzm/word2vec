# (c) Gert den Neijsel, 2021
# This script is based on Windows Powershell version 7.1
# The script assumes it is located in the same directory as the *.evtx files
# Please note: if you see red text during execution, these are warnings, not errors.
$debug = 0 # 1 = Dont actually generate te log files (it takes too long).
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue' # This will supress the warnings. The difference between 'real' errors (try/catch) and these are vague.

# Select which logs should be used (select 1 of more):
$useSecurityLog = 1
$useApplicationLog = 1
$useSystemLog = 1


function getLogs{
	Write-Host "`nRetrieve and parse events from System-, Application- and Security event logs."
	Write-Host "The script assumes it is located in the same directory as the *.evtx files.`n."
	Write-Host "This might take a lot of time. Please be patient...`n"

	# Create some empty files in advance. This prevents me from writing code to select which files to use.
	Remove-Item '.\*.csv'
	New-Item -Path '.\Security-Events.csv' -ItemType File
	New-Item -Path '.\Application-Events.csv' -ItemType File
	New-Item -Path '.\System-Events.csv' -ItemType File
	
	If($debug -eq 0){
		If($useSecurityLog -eq 1){
			Write-Host "Started parsing Security Event log at $(Get-Date -Format u)`n"
			try{
				Get-WinEvent -Path '.\Security.evtx' | ForEach-Object {
					$Values = $_.Properties | ForEach-Object { $_.Value }
					
					# return a new object with the required information
					[PSCustomObject]@{
						TimeCreated   = $_.TimeCreated.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
						EventRecordID = $_.RecordID
						EventID       = "Securi_"+$_.ID
						Level		  = $_.LevelDisplayName
						Provider	  = $_.ProviderName
					}
				} | Export-Csv -Path '.\Security-Events.csv' -Delimiter ',' -Encoding UTF8 -Force -NoTypeInformation
			}
			catch {
				Write-Host "An error has occured:"
				Write-Host $_
			}
		}
		If($useApplicationLog -eq 1){
			Write-Host "Started parsing Application Event log at $(Get-Date -Format u)`n"
			try{
				Get-WinEvent -Path '.\Application.evtx' | ForEach-Object {
					$Values = $_.Properties | ForEach-Object { $_.Value }
					
					# return a new object with the required information
					[PSCustomObject]@{
						TimeCreated   = $_.TimeCreated.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
						EventRecordID = $_.RecordID
						EventID       = "Applic_"+$_.ID
						Level		  = $_.LevelDisplayName
						Provider	  = $_.ProviderName
					}
				} | Export-Csv -Path '.\Application-Events.csv' -Delimiter ',' -Encoding UTF8 -Force -NoTypeInformation
			}
			catch {
				Write-Host "An error has occured:"
				Write-Host $_
			}
		}
		If($useSystemLog -eq 1){
			Write-Host "Started parsing System Event log at $(Get-Date -Format u)`n"
			try{
				Get-WinEvent -Path '.\System.evtx' | ForEach-Object {
					$Values = $_.Properties | ForEach-Object { $_.Value }
					
					# return a new object with the required information
					[PSCustomObject]@{
						TimeCreated   = $_.TimeCreated.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
						EventRecordID = $_.RecordID
						EventID       = "System_"+$_.ID
						Level		  = $_.LevelDisplayName
						Provider	  = $_.ProviderName
					}
				} | Export-Csv -Path '.\System-Events.csv' -Delimiter ',' -Encoding UTF8 -Force -NoTypeInformation
			}
			catch {
				Write-Host "An error has occured:"
				Write-Host $_
			}
		}
	}

	Write-Host "Combine and parse log files. Started at $(Get-Date -Format u)`n"
	# Determine which log file contains the most recently created events. This limits the usability of the other log files.
	# Log files which have a standard size limit and are filled more quickly don't have older events because these are deleted in circular logs.
	# The purpose of the lines below is that we produce a csv file with a common date/time range for alle event logs.
	Get-Content '.\System-Events.csv' -head 1 | Out-File '.\AllEvents-oldest-dates.csv'
	Get-Content '.\System-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Get-Content '.\Application-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Get-Content '.\Security-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Import-Csv '.\AllEvents-oldest-dates.csv' | Sort-Object -Property 'TimeCreated' -Descending | Export-Csv -NoTypeInformation -Path '.\AllEvents-oldest-dates-sorted.csv'

	# Determine the earliest common date in all log files.
	$oldestCommon = (Import-CSV '.\AllEvents-oldest-dates-sorted.csv')[0].TimeCreated
	Write-Host "Oldest common date in all log files:" $oldestCommon

	# Copy files both '.\Security-Events.csv' and '.\Application-Events.csv' to a new file '.\AllEvents-temp.csv'
	# Throw out the header lines while copying or you get 3 duplicate header lines in the end.
	Get-Content '.\Security-Events.csv', '.\Application-Events.csv' | Select-String -Pattern 'TimeCreated' -NotMatch | Set-Content '.\AllEvents-temp.csv'

	# Combine all event logs to a single new one; '.\AllEvents.csv'
	Get-Content '.\System-Events.csv', '.\AllEvents-temp.csv' | Set-Content '.\AllEvents.csv'

	# Nu de gecombineerde eventlogs filteren zodat gemeenschappelijk datum/tijd bereik overblijft, sorteren op 'TimeCreated' en opnieuw als csv file opbouwen, zonder quotes en met spatie als delimiter.
	# Now filter the combine log files so that only a common date-time range remains. Sort on 'TimeCreated'. Format the csv file. Remove the quotes. Use space as a delimiter.
	Import-Csv -Path '.\AllEvents.csv' | Where-Object {$_.'TimeCreated' -ge $oldestCommon} | Sort-Object -Property 'TimeCreated' | Export-Csv -NoTypeInformation -UseQuotes Never -Delimiter ',' -Path '.\AllEvents-sorted.csv'

	Write-Host "Ready... The result is in '.\AllEvents.csv'`n"
	Write-Host "Time elapsed:"
}

# Measure elapsed time for the entire operation:
Measure-Command { getLogs | Out-Default}
