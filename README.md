# PoSh-CanLii.Org
A PowerShell Module for the [CanLii.Org API](https://github.com/canlii/API_documentation)

# Installation
```
git clone https://github.com/crlogic/PoSh-CanLii.Org.git

cd .\PoSh-CanLii.Org

Import-Module .\Posh-CanLii.Org.psm1
```

# Usage
An API key is required. It can be requested at https://www.canlii.org/en/feedback/feedback.html

## Retrieve list of databases
```PowerShell
Get-CanliiDatabases -APIkey $APIKey
```

## Retrieve specific caselaw
```PowerShell
Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw
```

## Retrieve caselaw metadata
```PowerShell
$caseLaw = Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw 
$caseLaw | Where title -match 'Sale of Shares' | Get-CanliiCaseMetadata
```

### Usage Aids
Use Get-help -Full for additional examples

# Use-Cases
- Export list of case metadata to CSV/Excel for further tracking/filtering

- Parse common metadata tags from output

# Todo
- Complete remaining API

- Include Pester tests (requires control results)
