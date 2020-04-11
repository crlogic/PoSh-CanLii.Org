<#
.Synopsis
   Retrieve the list of Canlii.org databases
.DESCRIPTION
   Retrieve the list of Canlii.org databases using the private REST API
.EXAMPLE
   Get-CanliiDatabases -APIkey $APIKey
.EXAMPLE
   Get-CanliiDatabases -APIkey $APIKey -Language fr
#>
function Get-CanLiiDatabases
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
            if ($error[0].Exception.response.statuscode -eq 'TooManyRequests') {
                throw 'API Quota exceeded, quitting'
            }
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
   Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw 
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

        [Parameter(ParameterSetName='Published',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$publishedAfter,

        [Parameter(ParameterSetName='Published',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$publishedBefore,

        [Parameter(ParameterSetName='Modified',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$modifiedAfter,

        [Parameter(ParameterSetName='Modified',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$modifiedBefore,

        [Parameter(ParameterSetName='Changed',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$changedAfter,

        [Parameter(ParameterSetName='Changed',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$changedBefore,

        [Parameter(ParameterSetName='Decision',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$decisionDateAfter,

        [Parameter(ParameterSetName='Decision',Mandatory=$true)]
        [ValidatePattern('YYYY-MM-DD')]
        [DateTime]$decisionDateBefore
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
        $baseURL = "https://api.canlii.org/v1/caseBrowse/$Language/$DatabaseId/?offset=0&resultCount=10000"
        $script:URI = ''
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
            if ($error[0].Exception.response.statuscode -eq 'TooManyRequests') {
                throw 'API Quota exceeded, quitting'
            }
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
   Get-CanliiDatabases -APIkey $APIKey | Where-Object databaseid -eq sklgb | Get-CanliiCaselaw | Where title -match 'Sale of Shares' | Get-CanliiCaseMetadata
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
            #$URI
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            if ($error[0].Exception.response.statuscode -eq 'TooManyRequests') {
                throw 'API Quota exceeded, quitting'
            }
        }
    }
}
