function New-CosmosCollection {
    <#
    .SYNOPSIS
    Creates a newCosmosDB Collection
    
    .DESCRIPTION
    Creates a new CosmosDB Collection in the specified Database
    
    .PARAMETER DatabaseName
    Name of the Database where the Collection should be created
    
    .PARAMETER CollectionName
    Name of the new Collection

    .PARAMETER PartitionKey
    Partition key for sharding collections larger than 10GB.  Setting this parameter configures the collection size to 'unlimited'.
    
    .PARAMETER OfferThroughput
    Request Units for collection to be created.  

    .PARAMETER CosmosDBVariables
    This is the Script variable generated by Connect-CosmosDB - no need to supply this variable, unless you get really creative
    
    .EXAMPLE
    New-CosmosCollection -DatabaseName MyPrivateCosmos -CollectionName TohuVaBohu

    .EXAMPLE
    New-CosmosCollection -DatabaseName MyPrivateCosmos -CollectionName TohuVaBohu -partitionKey "location" -offerThroughput 2000
    
    .NOTES
    https://docs.microsoft.com/en-us/rest/api/documentdb/create-a-collection
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage='Name of the Database containing the Collection')]
        [string]$DatabaseName,
        [Parameter(Mandatory=$true,
        HelpMessage='Name of your Collection')]
        [string]$CollectionName,
        [Parameter(Mandatory=$false,
        HelpMessage="Request Units for collection creation")]
        [string]$partitionKey,
        [Parameter(Mandatory=$false,
        HelpMessage="Partition key for sharding collections larger than 10GB")]
        [int]$OfferThroughput,
        [Parameter(Mandatory=$false,
        HelpMessage="Use Connect-CosmosDB to create this Variable collection")]
        [hashtable]$CosmosDBVariables=$Script:CosmosDBVariables
    )
    
    begin {
        Test-CosmosDBVariable $CosmosDBVariables
        $Database = $CosmosDBConnection[$($DatabaseName + '_db')]
        if (-not $Database) {
            Write-Warning "Database $DatabaseName not found"
            continue
        }
    }
    
    process {
        # Add preceeding forward slash if not present
        if ($partitionKey -notmatch "^/" -and $partitionKey) {$partitionKey = "/$partitionKey"}
            
        $Verb = 'POST'
        $Url = '{0}/{1}/colls' -f $CosmosDBVariables['URI'],$Database._self
        $ResourceType = 'colls'
        $Header = New-CosmosDBHeader -resourceId $Database._rid -resourceType $ResourceType -Verb $Verb -OfferThroughput $OfferThroughput
        $Body = @{id=$CollectionName}
        if ($partitionKey) { $Body.Add("partitionKey", @{"paths"=@($PartitionKey); "kind"="Hash"}) }
        $CosmosBody = $Body | ConvertTo-Json
        try {
            $Return = Invoke-RestMethod -Uri $Url -Headers $Header -Method $Verb -Body $CosmosBody -ErrorAction Stop
            $Return = Get-CosmosCollection -DatabaseName $DatabaseName -CollectionName $CollectionName
            $script:CosmosDBConnection[$Database.id][$CollectionName] = $Return
            Write-Verbose "Collection $CollectionName has been created"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
        }
    }
    
    end {
    }
}