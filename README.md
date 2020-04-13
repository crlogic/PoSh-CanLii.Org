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
Get-CanliiCaseDatabases -APIkey $APIKey
```

## Retrieve specific caselaw
```PowerShell
Get-CanliiCaseDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw
```

## Retrieve caselaw metadata
```PowerShell
$caseLaw = Get-CanliiCaseDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw 
$caseLaw | Where title -match 'Sale of Shares' | Get-CanliiCaseMetadata
```

### Usage Aids
Use Get-help -Full for additional examples

# Use-Cases
- Export list of case metadata to CSV/Excel for further tracking/filtering
```PowerShell
$database = Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq onltb
$caseLaw =  $database| Get-CanliiCaselaw -resultCount 25
$caseLaw | Get-CanliiCaseMetadata | Export-Csv MyList.csv
```

- Parse common metadata tags from output
```PowerShell
$database = Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq onltb
$caseLaw =  $database| Get-CanliiCaselaw -resultCount 25
$caseLawMetaData = $caseLaw | Get-CanliiCaseMetadata
$keywords = $caseLawMetaData.keywords.foreach({$_.split(' — ')})
$keywords | Group | Select count,name | Sort count -Descending
```

- Export a subset of parsed caselaw
```PowerShell
$database = Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq onltb
$caseLaw =  $database| Get-CanliiCaselaw -resultCount 25
$caseLawMetaData = $caseLaw | Get-CanliiCaseMetadata
$keywords = $caseLawMetaData.keywords.foreach({$_.split(' — ')})
$parsedkeywords = $keywords | Group | Select count,name | Sort count -Descending | Out-GridView -PassThru
$filteredMetaData = $caseLawMetaData | Where keywords -match ($parsedkeywords.name -join '|')
$filteredMetaData | Export-Csv MyList.csv
```

# Todo
- Include Pester tests (requires control results)
