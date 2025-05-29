# Browser
winget install Microsoft.Edge
winget install Google.Chrome
winget install Mozilla.Firefox
winget install Zen-Team.Zen-Browser

# Chat
winget install Microsoft.Teams
winget install SlackTechnologies.Slack
winget install Discord.Discord

# Windows
winget install Microsoft.PowerToys # https://github.com/microsoft/PowerToys

# Shell
winget install Microsoft.WSL
winget install Microsoft.WindowsTerminal
winget install Microsoft.PowerShell
winget install JanDeDobbeleer.OhMyPosh

Set-PSRepository PSGallery -InstallationPolicy Trusted
Set-PSResourceRepository PSGallery -Trusted

# Development Tools
winget install Git.Git
winget install GitHub.cli
winget install Microsoft.DotNet.SDK.9
winget install Python.Python.3.13
winget install Docker.DockerDesktop
winget install Docker.DockerCompose
winget install OpenJS.NodeJS
winget install Yarn.Yarn
winget install Microsoft.AzureCLI
Install-PSResource -Name Az -Repository PSGallery -Scope CurrentUser -Force
winget install Hashicorp.Terraform
winget install Microsoft.Azure.AztfExport
winget install Postman.Postman

# IDE
winget install Microsoft.VisualStudio.2022.Enterprise
winget install Microsoft.VisualStudioCode
winget install Microsoft.SQLServer.2019.Developer
winget install Microsoft.SQLServerManagementStudio
winget install Microsoft.AzureDataStudio
winget install JetBrains.ReSharper
winget install JetBrains.Rider
winget install JetBrains.WebStorm
winget install JetBrains.DataGrip

# Miscellaneous
winget install Skillbrains.Lightshot
winget install Nodepad++.Notepad++
winget install 7zip.7zip
winget install dotPDN.PaintDotNet