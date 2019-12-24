$RecDurationMins = 1
$RecTime = (Get-Date).AddMinutes(2)
$MaxRun = 4
$myenv = Get-Content .\Brio.postman_environment.json -raw | ConvertFrom-Json
$myenv.values | % {if($_.key -eq 'RecTime'){$_.value=$RecTime.tostring("yyyy-MM-ddTHH:mm:ssK")}}
$myenv | ConvertTo-Json -Depth 32 | Set-Content .\Brio.postman_environment.json
$addMins = (Get-Date).AddMinutes($RecDurationMins).tostring("yyyy-MM-ddTHH:mm:ssK")
$TimeSpan=New-TimeSpan -End $Rectime
$SleepDuration = $TimeSpan.TotalSeconds
$CurrentRun = 1

#First let's clear the logs
if (!(Test-Path -Path ".\output.log")) {echo (out-null)> .\output.log}


#Start logging the console output
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path .\output.log -append


while ($CurrentRun -le $MaxRun)
{
	#Directory to Archive my Postman Environment history, for troubleshooting purpose
	$RectimeString = $Rectime.tostring('MM-dd-HHmmss')
	if (!(Test-Path -Path ".\Archive$RectimeString")) {New-Item -Path "." -Name "Archive$RectimeString" -ItemType "directory"}
	
	#Run Postman Recording Jobs API call
	newman run -e .\Brio.postman_environment.json --export-environment Brio.postman_environment.json '.\Brio Recording.postman_collection.json'
	
	#Archive Postman Environment after recording triggered
	copy .\Brio.postman_environment.json ".\Archive$RectimeString\PostRec_Brio.postman_environment_Run$CurrentRun.json"
	
	<#Make sure to wait until the Recording Job has started before going to next steps
	Because Copy and Amberfin jobs cannot be queued#>
	if ($CurrentRun -eq 1) {
		Echo "---------------------First Run---------------------"
		start-sleep -s $SleepDuration
		Echo "-> Starting Copy at "(Get-Date).tostring('HH:mm:ss')
	} else {
		$SleepDuration = $RecDurationMins *60
		Echo "--------------------Run #$CurrentRun--------------------"
		start-sleep -s $SleepDuration
		Echo "-> Starting Copy at "(Get-Date).tostring('HH:mm:ss')
	}

	#Run Postman Avid and Backup Copy jobs API Call
	newman run -e .\Brio.postman_environment.json --export-environment Brio.postman_environment.json .\AvidAndBackupCopier.postman_collection.json
	
	#Archive Postman Environment after recording triggered
	copy .\Brio.postman_environment.json ".\Archive$RectimeString\PostCopy_Brio.postman_environment_Run$CurrentRun.json"

	#Run Postman Amberfin Transcoding jobs API Call
	#TODO
	
	#Go to next run
	$CurrentRun ++
	Echo "-> Starting Next Run at "(Get-Date).tostring('HH:mm:ss')
	if ($CurrenRun -le $MaxRun) {
	write-host "CurrentRun is currently at #$CurrentRun"
	} else {
	write-host "Ok this was the last run"
	}
	
}

Stop-Transcript