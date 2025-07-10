#### Powershell Scripts
The minimal powershell consists of following customizations,
- `Microsoft.PowerShell_profile.ps1`: high level initializations
- `Init.ps1`: second level initializations
  - `Init-App.ps1`: helper for initialization of Apps  
  
*This shell prefers utlization of less number of Env Path variables. To update variable for applications please utilize `Init-App.ps1`.*
