#*******************************************************************************
# Licensed Materials - Property of IBM
# "Restricted Materials of IBM"
#
# Copyright IBM Corp. 2017 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
#*******************************************************************************

"*****************************************************"
"**          Running Microclimate installer         **"
"*****************************************************"
""
$cli_path = Split-Path -parent $PSCommandPath
$top_path = Split-Path -parent $cli_path

# Check whether the Microclimate CLI is already on the user's PATH
if ($env:path.Contains("microclimate\cli")) {
    "Updating existing PATH entry for Microclimate CLI (mcdev command)"
    $env:path = $env:path -replace "[^;]*microclimate\\cli", $cli_path

} else {
    "Adding Microclimate CLI (mcdev command) to your PATH"
    if (!($env:path.EndsWith(";"))) {
        $env:path += ";" # add separator to user's PATH
    }
    $env:path += $cli_path
    $env:path += ";"
}

# Create microclimate-workspace directory
if ( -not (Test-Path $top_path/microclimate-workspace)) {
  mkdir $top_path/microclimate-workspace > $null
}

# Create .config directory
if ( -not (Test-Path $top_path/microclimate-workspace/.config)) {
  mkdir $top_path/microclimate-workspace/.config > $null
}

# Delete Git file if exists
if (Test-Path $top_path/microclimate-workspace/.config/git.config) {
  rm $top_path/microclimate-workspace/.config/git.config > $null
}

# Initialise Git name and email if they exist
$git_username = "Microclimate User"
$git_email = "microclimate.user@localhost"
$git_config = "$top_path/microclimate-workspace/.config/git.config"
if (git config --get user.name) {
  $git_username = $(git config --get user.name)
}
if (git config --get user.email) {
  $git_email = $(git config --get user.email)
}
echo ""
echo "Initialising Git name and email";
echo "user.name: $git_username"
echo "user.email: $git_email"
git config -f $git_config --add user.name $git_username
git config -f $git_config --add user.email $git_email

# Remove the cache logs files if they already exist
$parentDir = Split-Path -parent $PSScriptRoot
$websphereLibertyCacheFile = "$parentDir\cli\websphere-liberty-docker-cache.log"
if (Test-Path $websphereLibertyCacheFile) {
    Remove-Item $websphereLibertyCacheFile
}
$libertyCacheFile = "$parentDir\cli\liberty-docker-cache.log"
if (Test-Path $libertyCacheFile) {
    Remove-Item $libertyCacheFile
}
$springCacheFile = "$parentDir\cli\spring-docker-cache.log"
if (Test-Path $springCacheFile) {
    Remove-Item $springCacheFile
}

# Pull the latest Websphere Liberty Docker Image
""
echo "Pulling the latest websphere-liberty:webProfile7 docker image";
"Starting background job to pull  latest Liberty Docker image"
Start-Job -Name "Liberty-Docker-Caching" -ScriptBlock {
    $cacheFile = $args[0]

    docker pull websphere-liberty:webProfile7 | Out-File $cacheFile
    if ($LastExitCode -ne 0) {
        "Failed to pull latest liberty docker image, exit code: $LastExitCode" | Out-File $cacheFile -Append
    }
} -ArgumentList $websphereLibertyCacheFile | Out-File $websphereLibertyCacheFile -Append

# Pre-build the Liberty JDK Docker image if it doesn't already exist
""
"Checking for cached Liberty JDK Docker image"
# Check if the Liberty cache image already exists and whether or not the dockerfile exists
$imageOutput = docker images mc-liberty-jdk-cache -q
$FileExists = Test-Path $parentDir\dockerfiles\libertyDockerfile
if (! $imageOutput -And $FileExists) {
    # Start a background job to cache the Liberty image
    # Powershell background jobs don't output the commands it runs, only the metadata for the job. So need to send its output to a file,
    # as well as all of the output of all of the commands it runs.
    "Starting background job to build Liberty JDK Docker image"
    Start-Job -Name "Liberty-App-Caching" -ScriptBlock {
        # Parse the args, we don't have access to the variables defined outside of the script block, so need to pass it in
        $parentDir = $args[0]
        $cacheFile = $args[1]

        # Run the docker build for the cache image, and check if it failed
        docker build -t mc-liberty-jdk-cache -f $parentDir\dockerfiles\libertyDockerfile $parentDir\dockerfiles | Out-File $cacheFile
        if ($LastExitCode -ne 0) {
            "Failed to build liberty app image, exit code: $LastExitCode" | Out-File $cacheFile  -Append
        }
    } -ArgumentList $parentDir, $libertyCacheFile | Out-File $libertyCacheFile  -Append
}

# Pre-build the Spring JDK Docker image if it doesn't already exist, using a background job.
""
"Checking for cached Spring JDK Docker image"
# Check if the Spring cache image already exists and whether or not the dockerfile exists
$imageOutput = docker images mc-spring-jdk-cache -q
$FileExists = Test-Path $parentDir\dockerfiles\springDockerfile
if (! $imageOutput -And $FileExists) {
    # Start a background job to cache the Spring image
    # Powershell background jobs don't output the commands it runs, only the metadata for the job. So need to send its output to a file,
    # as well as all of the output of all of the commands it runs.
    "Starting background job to build Spring JDK Docker image"
    Start-Job -Name "Spring-App-Caching" -ScriptBlock {
        # Parse the args, we don't have access to the variables defined outside of the script block, so need to pass it in
        $parentDir = $args[0]
        $cacheFile = $args[1]

        # Run the docker build for the cache image, and check if it failed
        docker build -t mc-spring-jdk-cache -f $parentDir\dockerfiles\springDockerfile $parentDir\dockerfiles | Out-File $cacheFile
        if ($LastExitCode -ne 0) {
            "Failed to build spring app image, exit code: $LastExitCode" | Out-File $cacheFile
        }
    } -ArgumentList $parentDir, $springCacheFile | Out-File $springCacheFile 
}

""
"Microclimate CLI installed. Run 'mcdev help' for usage instructions"
""
