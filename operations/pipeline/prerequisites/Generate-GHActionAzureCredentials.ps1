<#
    This Script will generate a Service Principal to be used in Azure Login Github Action as a Secret 
#>
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SpnName="santatech-web-deploy-spn",
    # Parameter help description
    [Parameter()]
    [string]
    $EnvironmentVariableName = 'AZURE_CREDENTIALS'
)
# Create Service Principal with Az Cli as it already generates a Secret and able to print out result in SDK expected format
# See this link for more information https://github.com/marketplace/actions/azure-login
$SPNCreds = az ad sp create-for-rbac --name $SpnName --sdk-auth --role contributor

# Save the SPN Credentials to a local file so you can use it to create your Github Repository Secret
$SPNCreds | Set-Content -Path "./$EnvironmentVariableName.json" -Force

