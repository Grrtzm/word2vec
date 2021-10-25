# Dit script is gebaseerd op Windows Powershell versie 7.1
# Let op: Als het uitvoeren rode tekst oplevert dan zijn dit warnings en geen errors.
$debug = 0 # 1 = Niet werkelijk de logfiles genereren (dit duurt lang).
$WarningPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue' # Hiermee ook de hierboven beschreven rode tekst verwijderen. Het onderscheid tussen 'echte' fouten (try/catch) en deze is vaag.

# Selecteer welke logs te gebruiken (selecteer 1 of meerdere):
$useSecurityLog = 1
$useApplicationLog = 1
$useSystemLog = 1

function getLogs{
	Write-Host "`nOphalen en verwerken van events uit System-, Application- en Security event logs."
	Write-Host "Dit kan 10 minuten duren...`n"

	# Alvast een paar lege bestanden aanmaken. Dit voorkomt dat ik code moet schrijven om te selecteren welke bestanden ik gebruik.
	Remove-Item '.\*.csv'
	New-Item -Path '.\Security-Events.csv' -ItemType File
	New-Item -Path '.\Application-Events.csv' -ItemType File
	New-Item -Path '.\System-Events.csv' -ItemType File
	
	If($debug -eq 0){
		If($useSecurityLog -eq 1){
			Write-Host "Uitlezen van Security Event log...`n"
			# Get-WinEvent  -MaxEvents 25 -Path 'D:\logs\winevt\Security.evtx' | ForEach-Object {
			try{
				Get-WinEvent -Path 'D:\logs\winevt\Security.evtx' | ForEach-Object {
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
				Write-Host "Er is een fout opgetreden:"
				Write-Host $_
			}
		}
		If($useApplicationLog -eq 1){
			Write-Host "Uitlezen van Application Event log...`n"
			try{
				Get-WinEvent -Path 'D:\logs\winevt\Application.evtx' | ForEach-Object {
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
				Write-Host "Er is een fout opgetreden:"
				Write-Host $_
			}
		}
		If($useSystemLog -eq 1){
			Write-Host "Uitlezen van System Event log...`n"
			try{
				Get-WinEvent -Path 'D:\logs\winevt\System.evtx' | ForEach-Object {
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
				Write-Host "Er is een fout opgetreden:"
				Write-Host $_
			}
		}
	}

	# Van alle eventlogs bepalen welke eventlog de meest recente begindatum heeft zodat alle logregels ouder dan dat weggegooid kunnen worden.
	# Het doel is dat uit alle logfiles een gemeenschappelijk datum/tijd bereik overblijft.
	Get-Content '.\System-Events.csv' -head 1 | Out-File '.\AllEvents-oldest-dates.csv'
	Get-Content '.\System-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Get-Content '.\Application-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Get-Content '.\Security-Events.csv' -tail 1 | Add-Content '.\AllEvents-oldest-dates.csv'
	Import-Csv '.\AllEvents-oldest-dates.csv' | Sort-Object -Property 'TimeCreated' -Descending | Export-Csv -NoTypeInformation -Path '.\AllEvents-oldest-dates-sorted.csv'

	# Bepalen van oudste datum die in alle logfiles voorkomt om hiermee te kunnen filteren.
	$oldestCommon = (Import-CSV '.\AllEvents-oldest-dates-sorted.csv')[0].TimeCreated
	Write-Host "Oudste datum die in alle logfiles voorkomt:" $oldestCommon

	# Kopieer de bestanden '.\Security-Events.csv' en '.\Application-Events.csv' samen naar een nieuw bestand '.\AllEvents-temp.csv'
	# en gooi tijdens het kopiëren de header regels eruit (anders zit je na het samenvoegen van 3 bestanden met overbodige header regels).
	Get-Content '.\Security-Events.csv', '.\Application-Events.csv' | Select-String -Pattern 'TimeCreated' -NotMatch | Set-Content '.\AllEvents-temp.csv'

	# Combineer alle eventlogs nu naar één nieuwe; '.\AllEvents.csv'
	Get-Content '.\System-Events.csv', '.\AllEvents-temp.csv' | Set-Content '.\AllEvents.csv'

	# Nu de gecombineerde eventlogs filteren zodat gemeenschappelijk datum/tijd bereik overblijft, sorteren op 'TimeCreated' en opnieuw als csv file opbouwen, zonder quotes en met spatie als delimiter.
	Import-Csv -Path '.\AllEvents.csv' | Where-Object {$_.'TimeCreated' -ge $oldestCommon} | Sort-Object -Property 'TimeCreated' | Export-Csv -NoTypeInformation -UseQuotes Never -Delimiter ',' -Path '.\AllEvents-sorted.csv'

	Write-Host "Klaar... Het resultaat staat in '.\AllEvents-sorted.csv'`n"
	Write-Host "Totale verwerkingstijd:"
}

# Tijdsduur van het geheel meten:
Measure-Command { getLogs | Out-Default}
