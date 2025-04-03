# The first time the Terminal-Icons module needs to be installed:
# Install-Module -Name Terminal-Icons -Repository PSGallery
Import-Module Terminal-Icons

# History
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

function src {
    cd "~/src/$args"
}

# Inspired by Scott Hanselman's profile: https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3
Set-PSReadLineKeyHandler -Key Ctrl+Shift+b `
  -BriefDescription BuildCurrentDirectory `
  -LongDescription "Build the current directory" `
  -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

    if (Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm run build")
    } else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
 
Set-PSReadLineKeyHandler -Key Ctrl+Shift+t `
  -BriefDescription BuildCurrentDirectory `
  -LongDescription "Build the current directory" `
  -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

    if (Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm run test")
    } else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet test")
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
 
Set-PSReadLineKeyHandler -Key Ctrl+Shift+s `
  -BriefDescription StartCurrentDirectory `
  -LongDescription "Start the current directory" `
  -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

    if (Test-Path -Path ".\package.json") {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("npm start")
    }else {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet run")
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }