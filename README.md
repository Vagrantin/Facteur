#Concept#
The goal of this Postman collection set is to automate the Brio recording and various copy/transcoding in while for testing purpose.

## Model ##
Those queries are design to work as a set, where the start point is the "Brio recording" collection and few seconds after the recording is started
the other jobs are triggered.
**This set of Postman collection is doing:**
Trigger Brio Recording jobs
Trigger Brio Backup Copier jobs
Trigger Brio AvidCopier jobs
Trigger Amberfin transcoding Workflow


#### Assumptions ####
We have only 1 Brio, 1 Ambrefin, 1 Nexis, 1 IPWS/Interplay Engine, 1 NAS.
Recording is performed on Brio with 4Channels named respectively "RecA,RecB,RecC,RecD".


### Requirements ###
[Postman](https://www.getpostman.com/)
[Newman](https://learning.getpostman.com/docs/postman/collection-runs/command-line-integration-with-newman/)
[Powershell](https://docs.microsoft.com/en-us/powershell/)
[NodeJS](https://nodejs.org/en/download/)

## Script ##

The purpose of the powershell script is to automate as much as possible Newman which is the cli tool to run Postman's Collections.
Parameters:
-d : Brio Recording duration to be set in minutes
-i : Number of iteration for each collection to run 

This script is first triggering all the Brio recording jobs (based on "-i"),then trigger the copies and transcoding jobs one after the other between each iteration it waits for the recording duration.
The first record starts 2mins after the script has been triggered.


## Postman ##

### Set machine name or IP###

In each collection in the Pre-request Scripts section set the variable to correct DNS name or IP address:
BrioMachineNameOrIP
AmberfinMachineNameOrIP
NASMachineNameOrIP
IPWSMachineNameOrIP

### Set storage path ###

#### Amberfin ####
Replace SRCSTORAGE by the name or IP of the source storage from which Ambrefin will read the media file and  SRCFOLDERA by the folder in which those medias are accessible
Replace NAS by the name or IP of the target storage where  Ambrefin will write the transcoded | rewrapped media file and  TRGFOLDER by the folder in which those medias are written.
This query is triggering an Amberfin WF:
name : Transcode-01
Conversion job : Proxy 640 x 360 640kbps

#### Brio ####

Avid integration:
To set the Avid Interplay password go to "manage environement" and update the "password" variable for the "Brio" environement.
