$myenv = Get-Content .\Brio.postman_environment1.json -raw | ConvertFrom-Json
$FindRecDuration = $myenv.values | Where-Object {$_.Key -eq "RecDurationMins"}
$RecDurationMins = $FindRecDuration.value
$RecTime = (Get-Date).AddMinutes(2)
$MaxRun = 18
$myenv.values | % {if($_.key -eq 'RecTime'){$_.value=$RecTime.tostring("yyyy-MM-ddTHH:mm:ssK")}}
$myenv | ConvertTo-Json -Depth 32 | Set-Content .\Brio.postman_environment1.json
$addMins = (Get-Date).AddMinutes($RecDurationMins).tostring("yyyy-MM-ddTHH:mm:ssK")
$TimeSpan=New-TimeSpan -End $Rectime.AddMinutes($RecDurationMins).AddMinutes(-2)
$SleepDuration = $TimeSpan.TotalSeconds
$CurrentRun = 1


#Stop any running logging
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
#First let's clear the logs
if (Test-Path -Path ".\output.log") {clear-content -Force .\output.log}

#Start logging the console output
Start-Transcript -path .\output.log -append


while ($CurrentRun -le $MaxRun)
{
	$NextRun = $CurrentRun +1
	
	#Directory to Archive my Postman Environment history, for troubleshooting purpose
	$RectimeString = $Rectime.tostring('MM-dd-HHmmss')
	if (!(Test-Path -Path ".\Archive$RectimeString")) {New-Item -Path "." -Name "Archive$RectimeString" -ItemType "directory"}
	
	#Run Postman Recording Jobs API call
	newman run -e .\Brio.postman_environment$CurrentRun.json --export-environment Brio.postman_environment$NextRun.json '.\Brio Recording.postman_collection.json' --delay-request 10
	
	#Archive Postman Environment after recording triggered
	copy .\Brio.postman_environment$CurrentRun.json ".\Archive$RectimeString\PostRec_Brio.postman_environment_Run$CurrentRun.json"
	
	<#Make sure to wait until the Recording Job has started before going to next steps
	Because Copy and Amberfin jobs cannot be queued#>
	if ($CurrentRun -eq 1) {
		Echo "---------------------First Run---------------------"
		Echo "waiting for $SleepDuration Secondes"
		start-sleep -s $SleepDuration
		Echo "-> Starting Copy at "(Get-Date).tostring('HH:mm:ss')
	} else {
		$SleepDuration = [int]$RecDurationMins *60
		Echo "--------------------Run #$CurrentRun--------------------"
		Echo "waiting for $SleepDuration Secondes"
		start-sleep -s $SleepDuration
		Echo "-> Starting Copy at "(Get-Date).tostring('HH:mm:ss')
	}

	#Run Postman Avid and Backup Copy jobs API Call
	newman run -e .\Brio.postman_environment$NextRun.json .\AvidAndBackupCopier.postman_collection.json
	
	#Run Postman Amberfin Transcoding jobs API Call
	#TODO
	
	#Go to next run
	$CurrentRun ++
	Echo "-> Starting Next Run at "(Get-Date).tostring('HH:mm:ss')
	if ($CurrentRun -le $MaxRun) {
	write-host "CurrentRun is currently at #$CurrentRun"
	} else {
	write-host "Ok this was the last run"
	}
	
}

Stop-Transcript