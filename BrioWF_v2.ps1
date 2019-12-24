$myenv = Get-Content .\Brio.postman_environment1.json -raw | ConvertFrom-Json
$FindRecDuration = $myenv.values | Where-Object {$_.Key -eq "RecDurationMins"}
$RecDurationMins = $FindRecDuration.value
$RecTime = (Get-Date).AddMinutes(2)
$MaxRun = 3
$myenv.values | % {if($_.key -eq 'RecTime'){$_.value=$RecTime.tostring("yyyy-MM-ddTHH:mm:ssK")}}
$myenv | ConvertTo-Json -Depth 32 | Set-Content .\Brio.postman_environment1.json
$addMins = (Get-Date).AddMinutes($RecDurationMins).tostring("yyyy-MM-ddTHH:mm:ssK")
$CurrentRun = 1


#Stop any running logging
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
#Start logging the console output, erase any previous logging information.
Start-Transcript -path .\output.log


	while ($CurrentRun -le $MaxRun)
	{
		$NextRun = $CurrentRun +1
		
		#Directory to Archive my Postman Environment history, for troubleshooting purpose
		$RectimeString = $Rectime.tostring('MM-dd-HHmmss')
		if (!(Test-Path -Path ".\Archive$RectimeString")) {New-Item -Path "." -Name "Archive$RectimeString" -ItemType "directory"}
		
		#Run Postman Recording Jobs API call
		newman run -e .\Brio.postman_environment$CurrentRun.json --export-environment Brio.postman_environment$CurrentRun.json '.\Brio Recording.postman_collection.json' --delay-request 10
		
		if ($CurrentRun -lt $MaxRun) {
		#Prepare Postman Environment for next run
		copy .\Brio.postman_environment$CurrentRun.json .\Brio.postman_environment$NextRun.json
		}
		
		#Archive Postman Environment after recording triggered
		if ($CurrentRun -eq 1) {
		
			copy .\Brio.postman_environment$CurrentRun.json ".\Archive$RectimeString\Brio.postman_environment$CurrentRun.json"
			} else {
			mv .\Brio.postman_environment$CurrentRun.json ".\Archive$RectimeString\Brio.postman_environment$CurrentRun.json"
		}
				
		#Go to next run
		$CurrentRun ++
		Echo "-> Starting Copy at $((Get-Date).tostring('HH:mm:ss'))"
		if ($CurrentRun -le $MaxRun) {
		Echo "---- Record ---- CurrentRun is currently at #$CurrentRun"
		} else {
		Echo "Ok this was the last run for Record jobs creation"
		$CurrentRun = 1
		break
		}
		
	}
	
$TimeSpan=New-TimeSpan -End $Rectime.AddSeconds(2)
$SleepDuration = $TimeSpan.TotalSeconds

	if ($SleepDuration -gt 0) {
	Echo "waiting for the Record jobs to start in $SleepDuration Secondes"
	start-sleep -s $SleepDuration
	}
	
Echo "-> Starting Copy at $((Get-Date).tostring('HH:mm:ss'))"

	while ($CurrentRun -le $MaxRun)
	{

		#Run Postman Avid and Backup Copy jobs API Call
		newman run -e .\Archive$RectimeString\Brio.postman_environment$CurrentRun.json .\AvidAndBackupCopier.postman_collection.json
			
		#Run Postman Amberfin Transcoding jobs API Call
		newman run -e .\Archive$RectimeString\Brio.postman_environment$CurrentRun.json .\Amberfin.postman_collection.json
		
		$SleepDuration = [int]$RecDurationMins *60
		Echo "--------------------Run #$CurrentRun--------------------"
		Echo "waiting for $SleepDuration Secondes"
		start-sleep -s $SleepDuration
			
		$CurrentRun ++
		Echo "-> Starting Copy at $((Get-Date).tostring('HH:mm:ss'))"
		if ($CurrentRun -le $MaxRun) {
		Echo "---- Copy ---- CurrentRun is currently at #$CurrentRun"
		} else {
		Echo "Ok this was the last run for Copy jobs creation"
		$CurrentRun = 1
		break
		}
	}

Stop-Transcript