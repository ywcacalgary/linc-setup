Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-LincGoogleChrome {
    [CmdletBinding()]
    param()

    $installerPath = Join-Path $env:TEMP 'ChromeSetup.exe'
    $downloadUrl = 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'
    $chromeExeCandidates = @(
        Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'
        Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'
    )

    try {
        if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe') {
            Write-LincLog -Message 'Google Chrome is already installed. Skipping installation.' -Level Warning
            return
        }

        Write-LincLog -Message 'Downloading Google Chrome installer.'
        Invoke-LincDownload -Uri $downloadUrl -DestinationPath $installerPath

        Write-LincLog -Message 'Installing Google Chrome silently.'
        $process = Start-Process -FilePath $installerPath -ArgumentList '/silent /install' -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -ne 0) {
            throw "Chrome installer exited with code $($process.ExitCode)."
        }

        $chromeExe = $chromeExeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $chromeExe) {
            throw 'Chrome executable not found after installation.'
        }

        Write-LincLog -Message 'Setting Chrome as default browser.'

        # Force set Google Chrome as default browser for ALL users in Windows 11
        $xmlPath = "C:\DefaultApps.xml"

        Write-LincLog -Message "Exporting current default app associations."
        Dism /Online /Export-DefaultAppAssociations:$xmlPath | Out-Null

        Write-LincLog -Message "Updating XML to set Google Chrome as default."
        [xml]$xmlContent = Get-Content $xmlPath

        # Define the associations to change
        $targets = @(".htm", ".html", ".mhtml", ".shtml", ".xhtml", ".xml", "http", "https")

        foreach ($assoc in $xmlContent.DefaultAssociations.Association) {
            if ($targets -contains $assoc.Identifier) {
                $assoc.ProgId = "ChromeHTML"
                $assoc.ApplicationName = "Google Chrome"
            }
        }

        # Save updated XML
        $xmlContent.Save($xmlPath)

        Write-LincLog -Message "Importing updated default app associations for NEW users."
        Dism /Online /Import-DefaultAppAssociations:$xmlPath | Out-Null

        # Apply to existing users
        Write-LincLog -Message "Applying changes to EXISTING users."
        $users = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notin @("All Users","Default","Default User","Public") }

        foreach ($user in $users) {
            $userProfile = $user.FullName
            $assocFile = "$userProfile\AppData\Local\Microsoft\Windows\Shell\DefaultAppAssociations.xml"

            # Create directory if missing
            $assocDir = Split-Path $assocFile
            if (-not (Test-Path $assocDir)) {
                New-Item -ItemType Directory -Path $assocDir -Force | Out-Null
            }

            # Copy updated XML to user profile
            Copy-Item $xmlPath $assocFile -Force
        }

        Write-LincLog -Message "Forcing Windows to reload default app settings."
        Stop-Process -Name explorer -Force
        Start-Process explorer

        Write-LincLog -Message "Google Chrome is now the default browser for ALL users."

        Write-LincLog -Message 'Google Chrome installation complete.' -Level Success
    }
    catch {
        Write-LincLog -Message "Chrome installation failed: $($_.Exception.Message)" -Level Error
        throw
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-LincZoom {
    [CmdletBinding()]
    param()

    $installerPath = Join-Path $env:TEMP 'ZoomInstallerFull-x64.msi'
    $downloadUrl = 'https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64'
    $zoomExeCandidates = @(
        'C:\Program Files\Zoom\bin\Zoom.exe'
        'C:\Program Files (x86)\Zoom\bin\Zoom.exe'
    )

    try {
        $existingZoom = $zoomExeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($existingZoom) {
            Write-LincLog -Message 'Zoom is already installed. Skipping installation.' -Level Warning
            return
        }

        Write-LincLog -Message 'Downloading Zoom installer.'
        Invoke-LincDownload -Uri $downloadUrl -DestinationPath $installerPath

        Write-LincLog -Message 'Installing Zoom silently.'
        $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -ne 0) {
            throw "Zoom installer exited with code $($process.ExitCode)."
        }

        Write-LincLog -Message 'Zoom installation complete.' -Level Success
    }
    catch {
        Write-LincLog -Message "Zoom installation failed: $($_.Exception.Message)" -Level Error
        throw
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
        }
    }
}

Export-ModuleMember -Function Install-LincGoogleChrome, Install-LincZoom