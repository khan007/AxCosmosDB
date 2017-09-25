function Remove-CosmosDocument {
    <#
    .SYNOPSIS
    Removes a Cosmos Document
    
    .DESCRIPTION
    Removes a single Cosmos Document
    
    .PARAMETER DatabaseName
    Name of the Database containing the Collection containing the document you want to delete
    
    .PARAMETER CollectionName
    Name of the Collection containing the document you want to delete
    
    .PARAMETER DocumentId
    The DocumentId of the document you want to delete
    
    .PARAMETER CosmosDBVariables
    This is the Script variable generated by Connect-CosmosDB - no need to supply this variable, unless you get really creative
    
    .EXAMPLE
    Remove-CosmosDocument -DatabaseName MyPrivateCosmos -CollectionName Chaos -DocumentId "c3210778-0ac2-4bc8-b0dd-d465192bf2c8"
    
    .NOTES
    https://docs.microsoft.com/en-us/rest/api/documentdb/delete-a-document
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage='Name of the Database containing the Document')]
        [string]$DatabaseName,
        [Parameter(Mandatory=$true,
        HelpMessage='Name of the Collection containing the Document')]
        [string]$CollectionName,
        [Parameter(Mandatory=$true,
        HelpMessage='Id of the Document')]
        [string]$DocumentId,
        [Parameter(Mandatory=$false,
        HelpMessage="Use Connect-CosmosDB to create this Variable collection")]
        [hashtable]$CosmosDBVariables=$Script:CosmosDBVariables
    )
    
    begin {
        Test-CosmosDBVariable $CosmosDBVariables
        $Database = $Script:CosmosDBConnection[($DatabaseName + '_db')]
        if (-not $Database) {
            Write-Warning "$DatabaseName not found"
            continue
        }
        $Collection = $Script:CosmosDBConnection[$DatabaseName][$CollectionName]
        if (-not $Collection) {
            Write-Warning "$CollectionName not found"
            continue
        }
    }
    
    process {
        $CurrentDocument = Get-CosmosDocument -DatabaseName $DatabaseName -CollectionName $CollectionName -DocumentId $DocumentId
        if (-not $CurrentDocument) {
            Write-Warning "Document $DocumentID not found in collection $CollectionName in database $DatabaseName"
            continue
        }
        $Verb = 'DELETE'
        $Url = '{0}/{1}' -f $CosmosDBVariables['URI'],$CurrentDocument._self
        $ResourceType = 'docs'
        $Header = New-CosmosDBHeader -resourceId $CurrentDocument._rid -resourceType $ResourceType -Verb $Verb
        try {
            $Return = Invoke-RestMethod -Uri $Url -Headers $Header -Method $Verb -Body $CosmosBody 
            Write-Verbose "$DocumentId has been deleted in $CollectionName"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
        }
    }
    
    end {
    }
}