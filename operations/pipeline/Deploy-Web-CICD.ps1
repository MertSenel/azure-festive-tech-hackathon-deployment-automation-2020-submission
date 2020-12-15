[CmdletBinding()]
param (
    # Name of the Environment Variable Script will get the Azure SPN Credentials
    [Parameter()][string]$EnvironmentVariableName = 'AZURE_CREDENTIALS',
    [Parameter()][string]$ArmTemplateFilePath = './operations/ARM/web/mstswl2020.web.json',
    [Parameter()][string]$ArmTemplateParameterFilePath = './operations/ARM/web/mstswl2020.web.parameters.json',
    [Parameter()][string]$project = "mstswl2020",
    [Parameter()][string]$env = 'prd',
    [Parameter()][switch]$DeployInfra,
    [Parameter()][switch]$CleanUpResources
)

#Setup config and credentials
$localSpnCreds = Get-ChildItem -Path "Env:\$EnvironmentVariableName"
$spn = $localSpnCreds.Value | ConvertFrom-Json

$ArmTemplateParameters = Get-Content -Path $ArmTemplateParameterFilePath | ConvertFrom-Json -Depth 10
$config = $ArmTemplateParameters.parameters.config.value

#region Curate Variables
$SubscriptionId = $spn.subscriptionId
$config = Get-Content $ArmTemplateParameterFilePath | ConvertFrom-Json
$ResourceGroupName = "$($config.parameters.project.value)-$($config.parameters.env.value)-web-rg"
$Location = "$($config.parameters.ProjectRGLocation.value)"
$DeploymentName = "SantaTech-$($(new-guid))"
#endregion

Write-Output "Resource Group Name is: $($ResourceGroupName)"

#region Connect To Azure if Not connected Already
$CurrentContext = Get-AzContext

if ((!$CurrentContext) -or ($CurrentContext.Subscription.Id -ne $SubscriptionId)) {
    [string]$clientId = $spn.clientId
    [string]$clientSecret = $spn.clientSecret
    # Convert to SecureString
    [securestring]$secClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    [pscredential]$spnCreds = New-Object System.Management.Automation.PSCredential ($clientId, $secClientSecret)
    Connect-AzAccount -ServicePrincipal -Credential $spnCreds -Tenant $spn.tenantId -Scope Process | out-null
    Set-AzContext -Subscription $SubscriptionId | Out-Null
}
#endregion

if ($DeployInfra) {
    New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location -Force | out-null
    $DeploymentARGS = @{
        Name                  = $DeploymentName
        ResourceGroupName     = $ResourceGroupName
        TemplateFile          = $ArmTemplateFilePath
        TemplateParameterFile = $ArmTemplateParameterFilePath
        Verbose               = $true
        ErrorAction           = 'Stop'
    }

    Write-Output "Start ARM Deployment"
    $AzDeployment = New-AzResourceGroupDeployment @DeploymentARGS
    $trafficManagerFQDN = $AzDeployment.Outputs.trafficManagerFQDN.value
    Write-Output "End ARM Deployment"
    Write-Output "Deployment Complete Santa is waiting for your wishes at: http://$($trafficManagerFQDN)"
}


#Clean Up
if ($CleanUpResources) {
    Write-Output "Force Delete ResourceGroup and Azure Resources as CleanUpResources Flag is Passed"
    $RgRemovalResult = Remove-AzResourceGroup -Name $ResourceGroupName -Force
}
