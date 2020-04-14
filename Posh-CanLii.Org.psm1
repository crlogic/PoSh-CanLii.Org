<#
.Synopsis
   Retrieve the list of Canlii.org case databases
.DESCRIPTION
   Retrieve the list of Canlii.org case databases using the private REST API
.EXAMPLE
   Get-CanLiiCaseDatabases -APIkey $APIKey
.EXAMPLE
   Get-CanLiiCaseDatabases -APIkey $APIKey -Language fr
#>
function Get-CanLiiCaseDatabases
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(Mandatory=$false)]
        [ValidateSet('en','fr')]
        $Language = 'en'
    )
    Begin {
        class CanliiDatabase {
            [string]$databaseid
            [string]$jurisdiction
            [string]$name

            CanliiDatabase([pscustomobject]$caseDatabases) {
                $this.databaseId = $caseDatabases.databaseId
                $this.jurisdiction = $caseDatabases.jurisdiction
                $this.name = $caseDatabases.name
                $this.APIkey = $null
            }
            hidden [string]$APIkey
        }    
    }
    Process {
        $URI = "https://api.canlii.org/v1/caseBrowse/$Language/?api_key=$APIKey"
        try {
            $caseDatabases = Invoke-RestMethod -Uri $URI -ErrorAction Stop | Select-Object -ExpandProperty caseDatabases
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
        $Databases = foreach ($case in $caseDatabases) {
            [CanliiDatabase]$caseentry = $case
            $caseentry.apikey = $APIkey
            $caseentry
        }
        $Databases
    }
}

<#
.Synopsis
   Retrieve specific caselaw from a Canlii.org database
.DESCRIPTION
   Retrieve specific caselaw from a Canlii.org database using the private REST API
.EXAMPLE
   Get-CanliiCaselaw -DatabaseID sklgb -APIkey $APIKey
.EXAMPLE
   Get-CanLiiCaseDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw 
#>
function Get-CanliiCaselaw
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param
    (
        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Published')]
        [Parameter(ParameterSetName='Modified')]
        [Parameter(ParameterSetName='Changed')]
        [Parameter(ParameterSetName='Decision')]
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Published')]
        [Parameter(ParameterSetName='Modified')]
        [Parameter(ParameterSetName='Changed')]
        [Parameter(ParameterSetName='Decision')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('en','fr')]
        $Language = 'en',
        
        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Published')]
        [Parameter(ParameterSetName='Modified')]
        [Parameter(ParameterSetName='Changed')]
        [Parameter(ParameterSetName='Decision')]
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseId,

        [Parameter(ParameterSetName='Default')]
        [Parameter(ParameterSetName='Published')]
        [Parameter(ParameterSetName='Modified')]
        [Parameter(ParameterSetName='Changed')]
        [Parameter(ParameterSetName='Decision')]
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,10000)]
        [string]$resultCount = 10000,

        [Parameter(ParameterSetName='Published',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$publishedAfter,

        [Parameter(ParameterSetName='Published',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$publishedBefore,

        [Parameter(ParameterSetName='Modified',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$modifiedAfter,

        [Parameter(ParameterSetName='Modified',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$modifiedBefore,

        [Parameter(ParameterSetName='Changed',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$changedAfter,

        [Parameter(ParameterSetName='Changed',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$changedBefore,

        [Parameter(ParameterSetName='Decision',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$decisionDateAfter,

        [Parameter(ParameterSetName='Decision',Mandatory=$true,HelpMessage='Use YYYY-MM-DD date format')]
        [ValidateScript({Get-Date $_ -Format yyyy-MM-dd})]
        [String]$decisionDateBefore
    )
    Begin {
        class CanliiCase {
            [string]$databaseid
            [PSCustomObject]$caseId
            [string]$title
            [string]$citation

            CanliiCase() {}
            CanliiCase([pscustomobject]$canliicases) {
                $this.databaseId = $canliicases.databaseId
                $this.caseId = $canliicases.caseId
                $this.title = $canliicases.title
                $this.citation = $canliicases.citation
                $this.APIkey = $null
            }
            hidden [string] $APIkey
        }    
    }
    Process {
        $baseURL = "https://api.canlii.org/v1/caseBrowse/$Language/$DatabaseId/?offset=0&resultCount=$resultCount"
        switch ($PsCmdlet.ParameterSetName) {
            Published {$URI = "$baseURL&publishedAfter=$publishedAfter&publishedBefore=$publishedBefore&api_key=$APIKey"}
            Modified {$URI = "$baseURL&modifiedAfter=$modifiedAfter&modifiedBefore=$modifiedBefore&api_key=$APIKey"}
            Changed {$URI = "$baseURL&changedAfter=$changedAfter&changedBefore=$changedBefore&api_key=$APIKey"}
            Decision {$URI = "$baseURL&decisionDateAfter=$decisionDateAfter&decisionDateBefore=$decisionDateBefore&api_key=$APIKey"}      
            Default {$URI = "$baseURL&api_key=$APIKey"}
        }
        
        try {
            $canliiCases = Invoke-RestMethod -Uri $URI -ErrorAction Stop | Select-Object -ExpandProperty cases
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
        $Cases = foreach ($case in $canliiCases) {
            [Canliicase]$caseentry = $case
            $caseentry.apikey = $APIkey
            $caseentry
        }
        $Cases
    }
}

<#
.Synopsis
   Retrieve case specific metadata from a Canlii.org database
.DESCRIPTION
   Retrieve case specific metadata from a Canlii.org database using the private REST API
.EXAMPLE
   Get-CanliiCaseMetadata -DatabaseId sklgb -CaseId 1918canlii290 -APIkey $APIKey
.EXAMPLE
   Get-CanLiiCaseDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw |
     Where title -match 'Sale of Shares' | Get-CanliiCaseMetadata
#>
function Get-CanliiCaseMetadata
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$databaseid,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$caseId,

        [Parameter(Mandatory=$false)]
        [ValidateSet('en','fr')]
        $Language = 'en'
    )
    Process {
        switch -Regex ($caseId) {
            '@{en=' {$caseidentry = $caseid.Substring(5).trimend('}')}
            '@{fr=' {$caseidentry = $caseid.Substring(5).trimend('}')}
            default {$caseidentry = $caseid}
        }
        $URI = "https://api.canlii.org/v1/caseBrowse/$Language/$databaseId/$caseidentry/?api_key=$APIkey"
        try {
            Invoke-RestMethod -Uri $URI -ErrorAction Stop
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
    }
}

<#
.Synopsis
    Retrieve case specific references from a Canlii.org database
.DESCRIPTION
    Retrieve case specific references from a Canlii.org database using the private REST API including citedCases, citingCases and citedLegislations
.EXAMPLE
    Get-CanliiCaseCitor -DatabaseId sklgb -CaseId 1918canlii290 -citeType citedCases -APIkey $APIKey
.EXAMPLE
    Get-CanLiiCaseDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | 
        Get-CanliiCaselaw | Get-CanliiCaseCitor -citeType citedCases 
#>
function Get-CanliiCaseCitor
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$databaseid,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$caseId,

        [Parameter(Mandatory=$true)]
        [ValidateSet('citedCases','citingCases','citedLegislations')]
        $citeType
    )
    Process {
        switch -Regex ($caseId) {
            '@{en=' {$caseidentry = $caseid.Substring(5).trimend('}')}
            '@{fr=' {$caseidentry = $caseid.Substring(5).trimend('}')}
            default {$caseidentry = $caseid}
        }
        $URI = "https://api.canlii.org/v1/caseCitator/en/$databaseId/$caseidentry/$($citeType)?api_key=$APIkey"
        try {
            Invoke-RestMethod -Uri $URI -ErrorAction Stop | Select-Object -ExpandProperty *
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
    }
}

# # Legislation

<#
.Synopsis
   Retrieve the list of Canlii.org legislation databases
.DESCRIPTION
   Retrieve the list of Canlii.org legislation databases using the private REST API
.EXAMPLE
   Get-CanLiiLegislationDatabases -APIkey $APIKey
.EXAMPLE
   Get-CanLiiLegislationDatabases -APIkey $APIKey -Language fr
#>
function Get-CanLiiLegislationDatabases
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(Mandatory=$false)]
        [ValidateSet('en','fr')]
        $Language = 'en'
    )
    Begin {
        class CanliiLegislationDatabase {
            [string]$databaseid
            [string]$type
            [string]$jurisdiction
            [string]$name

            CanliiDatabase([pscustomobject]$legislationDatabases) {
                $this.databaseId = $legislationDatabases.databaseId
                $this.type = $legislationDatabases.type
                $this.jurisdiction = $legislationDatabases.jurisdiction
                $this.name = $legislationDatabases.name
                $this.APIkey = $null
            }
            hidden [string]$APIkey
        }    
    }
    Process {
        $URI = "https://api.canlii.org/v1/legislationBrowse/$Language/?api_key=$APIKey"
        try {
            $legislationDatabases = Invoke-RestMethod -Uri $URI -ErrorAction Stop | Select-Object -ExpandProperty legislationDatabases
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
        $Databases = foreach ($case in $legislationDatabases) {
            [CanliiLegislationDatabase]$caseentry = $case
            $caseentry.apikey = $APIkey
            $caseentry
        }
        $Databases
    }
}

<#
.Synopsis
   Retrieve specific legislation from a Canlii.org legislation database
.DESCRIPTION
   Retrieve specific legislation from a Canlii.org legislation database using the private REST API
.EXAMPLE
   Get-CanliiLegislation -DatabaseID ska -APIkey $APIKey
.EXAMPLE
   Get-CanliiLegislationDatabases -APIkey $APIKey | Where-Object databaseid -eq ska | Get-CanliiLegislation 
#>
function Get-CanliiLegislation
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param
    (
        [Parameter(ParameterSetName='Default')]
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(ParameterSetName='Default')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('en','fr')]
        $Language = 'en',
        
        [Parameter(ParameterSetName='Default')]
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseId
    )
    Begin {
        class CanliiLegislation {
            [string]$databaseid
            [PSCustomObject]$legislationId
            [string]$title
            [string]$citation
            [string]$type

            CanliiCase() {}
            CanliiCase([pscustomobject]$canliilegislation) {
                $this.databaseId = $canliilegislation.databaseId
                $this.caseId = $canliilegislation.caseId
                $this.title = $canliilegislation.title
                $this.citation = $canliilegislation.citation
                $this.type = $canliilegislation.type
                $this.APIkey = $null
            }
            hidden [string] $APIkey
        }    
    }
    Process {
        $URI = "https://api.canlii.org/v1/legislationBrowse/$Language/$DatabaseId/?api_key=$APIKey"
        
        try {
            $canliilegislations = Invoke-RestMethod -Uri $URI -ErrorAction Stop | Select-Object -ExpandProperty legislations
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
        $Cases = foreach ($case in $canliilegislations) {
            [CanliiLegislation]$caseentry = $case
            $caseentry.apikey = $APIkey
            $caseentry
        }
        $Cases
    }
}

<#
.Synopsis
   Retrieve legislation specific metadata from a Canlii.org legislation database
.DESCRIPTION
   Retrieve legislation specific metadata from a Canlii.org legislation database using the private REST API
.EXAMPLE
   Get-CanliiLegislationMetadata -DatabaseId ska -LegislationId ss-1978-supp-c-14 -APIkey $APIKey
.EXAMPLE
   Get-CanLiiLegislationDatabases -APIkey $APIKey | Where-Object databaseid -eq ska | 
        Get-CanliiLegislation | Where title -match 'Relief Amendment Act' | Get-CanliiLegislationMetadata
#>
function Get-CanliiLegislationMetadata
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$APIkey,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$databaseid,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LegislationId,

        [Parameter(Mandatory=$false)]
        [ValidateSet('en','fr')]
        $Language = 'en'
    )
    Process {
        switch -Regex ($LegislationId) {
            '@{en=' {$legislationidentry = $legislationid.Substring(5).trimend('}')}
            '@{fr=' {$legislationidentry = $legislationid.Substring(5).trimend('}')}
            default {$legislationidentry = $legislationid}
        }
        $URI = "https://api.canlii.org/v1/legislationBrowse/$Language/$databaseId/$legislationidentry/?api_key=$APIkey"
        try {
            Invoke-RestMethod -Uri $URI -ErrorAction Stop
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            $canliiError = $error[0]
            if ($canliiError.Exception.response.statuscode -eq 'TooManyRequests') {
                Write-Warning 'API quota exceeded'
            }
            else {
                $canliiErrorMessage = $canliierror.errordetails.message | ConvertFrom-Json
                $warning = 'canlii.org says {0}: {1}' -f $canliiErrorMessage.error,$canliiErrorMessage.message
                Write-Warning $warning
            }
            throw 'Quitting due to API error'
        }
    }
}

