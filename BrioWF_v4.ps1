#$i is the number of iteration you want to run, if not set Default is 1 run.
#$d is the duration of the recording, if not set default is 1 minute.
param ( 
		[int]$i = 1,
		[int]$d = 1
)
#Load Postman environment JSON file
$myenv = Get-Content .\Brio.postman_environment1.json -raw | ConvertFrom-Json
$RecDurationMins = $d
#Set the number of iteration, which will be passed by an argument to the script.
$MaxRun = $i
#Set the start record time
$RecTime = (Get-Date).AddMinutes(2)
#Set the start record time in the Postman environment JSON file (stored as a PSObject at this stage)
$myenv.values | % {if($_.key -eq 'RecTime'){$_.value=$RecTime.tostring("yyyy-MM-ddTHH:mm:ssK")}}
#Set the record duration in the Postman environment JSON file (stored as a PSObject at this stage)
$myenv.values | % {if($_.key -eq 'RecDurationMins'){$_.value=$RecDurationMins}}
#Save back to JSON format the Postman environment
$myenv | ConvertTo-Json -Depth 32 | Set-Content .\Brio.postman_environment1.json
#$addMins = (Get-Date).AddMinutes($RecDurationMins).tostring("yyyy-MM-ddTHH:mm:ssK")
#initialize the first iteration
$CurrentRun = 1

	while ($CurrentRun -le $MaxRun)
	{
		$NextRun = $CurrentRun +1
		
		#Directory to Archive my Postman Environment history, for troubleshooting purpose
		$RectimeString = $Rectime.tostring('MM-dd-HHmmss')
		if (!(Test-Path -Path ".\Archive$RectimeString")) {New-Item -Path "." -Name "Archive$RectimeString" -ItemType "directory"}
		
		#Run Postman Recording Jobs API call
		newman run -e .\Brio.postman_environment$CurrentRun.json --export-environment Brio.postman_environment$CurrentRun.json '.\Brio Recording.postman_collection.json' --delay-request 10 2> $NULL
		
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
		Echo "-> Starting run at $((Get-Date).tostring('HH:mm:ss'))"
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
	Echo "Waiting for the Record jobs to start in $SleepDuration Secondes"
	start-sleep -s $SleepDuration
	}
	
Echo "-> Starting Copy and transcode Jobs at $((Get-Date).tostring('HH:mm:ss'))"

	while ($CurrentRun -le $MaxRun)
	{

		#Run Postman Avid and Backup Copy jobs API Call
		newman run -e .\Archive$RectimeString\Brio.postman_environment$CurrentRun.json .\AvidAndBackupCopier.postman_collection.json 2> $NULL
						
		#Echo "I will use this environment file '.\Archive$RectimeString\Brio.postman_environment$CurrentRun.json'"
		#Run Postman Amberfin Transcoding jobs API Call
		newman run -e .\Archive$RectimeString\Brio.postman_environment$CurrentRun.json .\Amberfin.postman_collection.json 2> $NULL
		
		$SleepDuration = $RecDurationMins *62
		Echo "--------------------Run #$CurrentRun--------------------"

		$CurrentRun ++
		
		if ($CurrentRun -le $MaxRun) {
		Echo "Waiting next run for $SleepDuration Secondes"
		start-sleep -s $SleepDuration
		Echo "-> Starting run at $((Get-Date).tostring('HH:mm:ss'))"
		#Echo "---- Copy ---- CurrentRun is currently at #$CurrentRun"
		} else {
		Echo "Ok this was the last run for Copy jobs creation"
		break
		}
	}