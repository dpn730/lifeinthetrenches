<#
    .SYNOPSIS
        This function is used to convert a CSV file into an AzureRM template parameters file/s.

    .DESCRIPTION
        This function takes an input CSV file and for each line it extracts the properties 
        and wraps it into an Azure Resource Management template parameter file in JSON format. 
        By default, the output filenames are of the following format: item-<count>.json. This 
        function is useful in scenarios where it is necessary to provision multiple resources 
        with the same set of parameters (with different values) in Azure.

    .PARAMETER CSVFile
        This parameter is a file path to a CSV file that will be used as the source object for the function. 
        This parameter is mutually exclusive to the "InputObject" parameter.
    
    .PARAMETER OutputPrefix
        This parameter is optional and it is used to specify the prefix prepended to the output files.

    .INPUTS
        This function can take a PowerShell object from the pipeline.

    .OUTPUTS
        This function returns a collection of the filenames the JSON files produced.

    .EXAMPLE
        ConvertTo-AzureRmParametersJSON -CSVFile .\TestFile.csv
        
        This example shows the usage of the function with a CSV file as input.

    .EXAMPLE
        ConvertTo-AzureRmParametersJSON -CSVFile .\TestFile.csv -OutputPrefix "test-"

        This example shows the usage of the function with a CSV file as input while also 
        configuring the prefix of output files.

    .LINK
        AzureRM Template Authoring: https://azure.microsoft.com/en-us/documentation/articles/resource-group-authoring-templates/
#>
function ConvertTo-AzureRmParametersJSON {

    Param (
        [Parameter(Mandatory=$true, ParameterSetName="CSVFile", ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $CSVFile,

        [Parameter(ParameterSetName="CSVFile")]
        [string] $OutputPrefix = "item-"
    )
    
    if($PSCmdlet.ParameterSetName -eq "CSVFile") {
        $sourceObj = Import-Csv $CSVFile
    }
    else {
        $sourceObj = $null
    }

    $outputFiles = @()
    $count = 0
    if($sourceObj) {
        # Evaluate each line item in the CSV
        foreach($item in $sourceObj) {

            # Create new PowerShell object to store JSON data
            $newObj = New-Object System.Object

            # Add standard properties of the parameter file to the object
            $newObj | Add-Member -Type NoteProperty -Name "`$schema" -Value `
                "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
            $newObj | Add-Member -Type NoteProperty -Name "contentVersion" -Value `
                "1.0.0.0"
            
            # Evaluate each property of the CSV line item
            $params = @{}
            $item.PsObject.Properties | ForEach-Object {            
                $name = $_.Name
                $value = $_.Value
                
                $valueObj = @{}
                $valueObj.Add("value",$value)

                $params.Add($name,$valueObj)
            }

            # Add "parameters" property to the object
            $newObj | Add-Member -Type NoteProperty -Name "parameters" -Value $params
            
            # Build output file name
            $fileName = $OutputPrefix + "$count.json"

            # Convert the PowerShell object to JSON and write the output file
            ConvertTo-Json -InputObject $newObj | Out-File $fileName
            
            $outputFiles += $fileName
            $count++
        }

        # Return data of the script
        $outputFiles
    }
    else {
        Write-Host "ERROR: Input CSV is null" -ForegroundColor Red
    }
} 