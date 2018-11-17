Param( [string]$command )

#*******************************************************************************
# Licensed Materials - Property of IBM
# "Restricted Materials of IBM"
#
# Copyright IBM Corp. 2017 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
#*******************************************************************************

function launch() { # note: 'start' is a reserved word in PowerShell
    "*****************************************************"
    "**                Starting Microclimate            **"
    "*****************************************************"
    $LastExitCode = 0

    # Get and start up the microclimate docker images
    docker-compose up -d
    if ($LastExitCode -ne 0) {
        "Microclimate: Error running docker-compose, exit code: $LastExitCode See previous messages"
        return
    }

    # Open up the microclimate portal in the user's browser
    $portal_port = $(docker inspect --format='{{range $p, $conf :=.NetworkSettings.Ports}}{{(index $conf 0).HostPort}}{{end}}' microclimate-portal)
    $count = 0
    while ($count++ -lt 30) { # max 30 secs then timeout
        $html_status = 0
        try {
            $html_status = (Invoke-WebRequest -method head -URI http://localhost:$portal_port).statuscode
        } catch {}
        if ($html_status -eq 200) {
            break # microclimate is up, good to go
        }
        Start-Sleep -s 1
    }
    start "http://localhost:$portal_port"
}

function open() {
    "*****************************************************"
    "**                Opening Microclimate             **"
    "*****************************************************"
    $portal_port = $(docker inspect --format='{{range $p, $conf :=.NetworkSettings.Ports}}{{(index $conf 0).HostPort}}{{end}}' microclimate-portal)
    start "http://localhost:$portal_port"
}

function update() {
    "*****************************************************"
    "**      Updating Microclimate docker images        **"
    "*****************************************************"
    docker-compose pull --parallel
}

function stop() {
    "*****************************************************"
    "**                Stopping Microclimate            **"
    "*****************************************************"
    $app_containers = docker ps -a -q  --filter name=mc
    if ($app_containers) {
        "Stopping project application containers"
        docker rm -f $app_containers
    }

    docker-compose down
}

function delete() {
    # First stop any running microclimate containers
    stop
    "*****************************************************"
    "**       Deleting Microclimate docker images       **"
    "*****************************************************"
    $docker_images = docker images -q "microclimate*"
    if ($docker_images) {
        docker rmi $docker_images
    }
    $docker_images = docker images -q "sys-mcs-docker-local.artifactory.swg-devops.com/microclimate*"
    if ($docker_images) {
        docker rmi $docker_images
    }
    $docker_images = docker images -q "ibmcom/microclimate*"
    if ($docker_images) {
        docker rmi $docker_images
    }
    $docker_images = docker images -q "mc-*"
    if ($docker_images) {
        docker rmi $docker_images
    }
    $docker_images = docker images -q "sys-mcs-docker-local.artifactory.swg-devops.com/mc-*"
    if ($docker_images) {
        docker rmi $docker_images
    }
    $docker_images = docker images -q "ibmcom/mc-*"
    if ($docker_images) {
        docker rmi $docker_images
    }
}

function showHelp() {
    "*****************************************************"
    "**                Microclimate CLI                 **"
    "*****************************************************"
    "Usage:	mcdev COMMAND [options]"
    ""
    "Commands:"
    "  start             Pull Microclimate docker images and start Microclimate"
    "  open              Open Microclimate in your browser"
    "  stop              Stop Microclimate docker containers"
    "  delete            Delete Microclimate docker images (stops Microclimate first)"
    "  update            Update Microclimate docker images"
    ""
}

$current_location = Get-Location
$script_location = Split-Path -parent $PSCommandPath

# Run all commands in the main microclimate project directory
Set-Location $script_location\..
# The docker commands expect environment variable $PWD to be set
$env:PWD = $script_location
# Workspace path needs to be in Unix format, e.g /C/Users/user/microclimate/microclimate-workspace
$workspace = "/$pwd/microclimate-workspace".Replace("\","/").Replace(":","")
$Env:WORKSPACE_DIRECTORY = $workspace
$Env:COMPOSE_CONVERT_WINDOWS_PATHS=1
$Env:HOST_OS = "windows"
$Env:PLATFORM=""

# Create the telemetry ID. Use try/catch block to prevent errors from displaying
# if there are issues getting the mac address via the getmac call
try {
    $macAddress = getmac | Select -Index 3
    $macSplit = $macAddress.split(' ')
    $macAddress = $macSplit[0].trim();
    $macAddress = $macAddress.replace('-',':')
    $telemetryID = $macAddress+$env:UserName
    $data = [system.Text.Encoding]::UTF8.GetBytes($telemetryID)
    $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $ResultHash = $sha1.ComputeHash($data)
    $result = ""
    foreach ($byte in $ResultHash) {$result+="{0:x2}" -f $byte}
    $Env:TELEMETRY = "Desktopid-" + $result
}
catch {}

switch ($command) {
    "start" {launch}
    "open" {open}
    "update" {update}
    "stop" {stop}
    "delete" {delete}
    "help" {showHelp}
    default {showHelp}
}

# Restore user to their current working directory
Set-Location $current_location
