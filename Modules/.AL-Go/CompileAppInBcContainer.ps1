Param(
    [Hashtable] $parameters
)


function Get-Baselines {
    Param(
    [string] $BaselineVersion,
    [string] $ApplicationName,
    [string] $ContainerName,
    [string] $AppSymbolsFolder
    )
    if(-not $BaselineVersion) {
        Write-Host "Baseline version is not defined"
    }
    else {
        Write-Host "Baseline version: $BaselineVersion"

        $baselineURL = Get-BCArtifactUrl -type Sandbox -country 'W1' -version $BaselineVersion # W1 because Modules are not localized
        if(-not $baselineURL) {
            throw "Unable to find URL for baseline version $BaselineVersion"
        }
        $baselineFolder = Join-Path $([System.IO.Path]::GetTempPath()) 'baselines'
        
        Write-Host "Baseline URL: $baselineURL"
        Write-Host "Downloading to: $baselineFolder"
        
        Download-Artifacts -artifactUrl $baselineURL -basePath $baselineFolder
        $baselineApp = Get-ChildItem -Path "$baselineFolder/sandbox/$BaselineVersion/w1/Extensions/*$ApplicationName*" -Filter "*.app"

        Write-Host "Container Name: $($ContainerName)"
        Write-Host "appSymbolsFolder: $($AppSymbolsFolder)"

        $containerSymbolsFolder = Get-BcContainerPath -containerName $ContainerName -path $AppSymbolsFolder
        $baselineAppName = $baselineApp.Name
        $containerPath = Join-Path $containerSymbolsFolder $baselineAppName

        Write-Host "Copying $($baselineApp.FullName) to $containerPath"

        Copy-FileToBcContainer -containerName $ContainerName -localPath $baselineApp.FullName -containerPath $containerPath

        Remove-Item -Path $baselineFolder -Recurse -Force
    }
}


Write-Host "BuildMode - $ENV:BuildMode"
$appBuildMode = $ENV:BuildMode

# $app is a variable that determine whether the current app is a normal app (not test app, for instance)
if($app)
{
    # Setup compiler features to generate captions and LCGs
    if (!$parameters.ContainsKey("Features")) {
        $parameters["Features"] = @()
    }
    $parameters["Features"] += @("generateCaptions")

    # Setup compiler features to generate LCGs for the default build mode
    if($appBuildMode -eq 'Default') {
        $parameters["Features"] += @("lcgtranslationfile")
    }
}

Get-Baselines -ContainerName $parameters.ContainerName -AppSymbolsFolder $parameters["appSymbolsFolder"] -ApplicationName "System Application" -BaselineVersion "21.4.52563.53749"

$appFile = Compile-AppInBcContainer @parameters #-CopySymbolsFromContainer 

$branchName = $ENV:GITHUB_REF_NAME

# Only add the source code to the build artifacts if the delivering is allowed on the branch 
if($branchName -and (($branchName -eq 'main') -or $branchName.StartsWith('release/'))) {
    $appProjectFolder = $parameters.appProjectFolder
    
    # Extract app name from app.json
    $appName = (Get-ChildItem -Path $appProjectFolder -Filter "app.json" | Get-Content | ConvertFrom-Json).name

    Write-Host "Current app name: $appName; app folder: $appProjectFolder"

    # Determine the folder where the artifacts for the package will be stored
    $holderFolder = 'Apps'
    if(-not $app) {
        $holderFolder = 'TestApps'
    }

    $packageArtifactsFolder = "$env:GITHUB_WORKSPACE/Modules/.buildartifacts/$holderFolder/Package/$appName/$appBuildMode" # manually construct the artifacts folder

    $buildArtifactsFolder = "$packageArtifactsFolder/BuildArtifacts"
    $sourceCodeFolder = "$packageArtifactsFolder/SourceCode"

    if(-not (Test-Path $packageArtifactsFolder)) {
        Write-Host "Creating $packageArtifactsFolder"
        New-Item -Path "$env:GITHUB_WORKSPACE/Modules" -Name ".buildartifacts/$holderFolder/Package/$appName/$appBuildMode" -ItemType Directory | Out-Null
    }

    Write-Host "Package artifacts folder: $packageArtifactsFolder"

    switch ( $appBuildMode )
    {
        'Default' { 
            # Add the generated Translations folder to the artifacts folder
            $TranslationsFolder = "$appProjectFolder/Translations"
            if (Test-Path $TranslationsFolder) {
                Write-Host "Translations were generated for app $appName"
                Copy-Item -Path $TranslationsFolder -Destination "$buildArtifactsFolder" -Recurse -Force | Out-Null
            } else {
                Write-Host "Translations were not generated for app $appName"
            }

            # Add the source code for test apps to the artifacts folder
            if(-not $app) {
                Copy-Item -Path $appProjectFolder -Destination "$sourceCodeFolder" -Recurse -Force | Out-Null
            }

            # Add  the app file for every built app to a folder
            Copy-Item -Path $appFile -Destination $packageArtifactsFolder -Force | Out-Null
         }
        'Translated' { 
            # Add the source code for non-test apps to the artifacts folder
            if($app) {
                Copy-Item -Path $appProjectFolder -Destination "$sourceCodeFolder" -Recurse -Force | Out-Null
            }

            # Add the app file for every built app to a folder
            Copy-Item -Path $appFile -Destination $packageArtifactsFolder -Force | Out-Null
        }

        'Clean' {
              # Add  the app file for every built app to a folder
              Copy-Item -Path $appFile -Destination $packageArtifactsFolder -Force | Out-Null
        }
    }
}

$appFile