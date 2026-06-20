# ============================================================
# PowerShell Sample — Zenith Readable Theme Test
# ============================================================

#region Parameters & Variables

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment = "dev",

    [int]$RetryCount = 3,
    [switch]$WhatIf
)

$script:ApiBaseUrl  = "https://management.azure.com"
$script:MaxTimeout  = 300
$private:SecretKey  = $env:APP_SECRET_KEY

#endregion

#region Helper Functions

function Get-AzureToken {
    <#
    .SYNOPSIS
        Retrieves an Azure bearer token using managed identity.
    #>
    [OutputType([string])]
    param ([string]$TenantId)

    try {
        $response = Invoke-RestMethod `
            -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2019-08-01&resource=https://management.azure.com/" `
            -Headers @{ Metadata = "true" } `
            -Method GET

        return $response.access_token
    }
    catch {
        Write-Error "Failed to retrieve token: $_"
        throw
    }
}

function Invoke-WithRetry {
    param (
        [scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 5
    )

    $attempt = 0
    do {
        $attempt++
        try {
            return & $ScriptBlock
        }
        catch {
            if ($attempt -ge $MaxAttempts) { throw }
            Write-Warning "Attempt $attempt failed. Retrying in ${DelaySeconds}s..."
            Start-Sleep -Seconds $DelaySeconds
        }
    } while ($attempt -lt $MaxAttempts)
}

#endregion

#region Main Logic

$token   = Get-AzureToken -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$headers = @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
}

$deploymentName = "deploy-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmm')"

$body = [PSCustomObject]@{
    properties = @{
        mode       = "Incremental"
        parameters = @{
            environment = @{ value = $Environment }
            retryCount  = @{ value = $RetryCount }
        }
    }
} | ConvertTo-Json -Depth 10

if ($WhatIf) {
    Write-Output "WhatIf: Would deploy '$deploymentName' to '$ResourceGroup'"
}
else {
    Invoke-WithRetry -ScriptBlock {
        $uri    = "$script:ApiBaseUrl/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$ResourceGroup/providers/Microsoft.Resources/deployments/$deploymentName?api-version=2021-04-01"
        $result = Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
        Write-Output "Deployment state: $($result.properties.provisioningState)"
    }
}

# Numeric and boolean literals
$port       = 8080
$pi         = 3.14159
$isEnabled  = $true
$isDisabled = $false
$nothing    = $null

# Switch statement
switch ($Environment) {
    "dev"  { Write-Output "Dev mode — verbose logging on" }
    "prod" { Write-Output "Prod mode — alerts active" }
    default { Write-Warning "Unknown environment: $Environment" }
}

# Pipeline
Get-ChildItem -Path . -Filter "*.log" -Recurse |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Sort-Object Length -Descending |
    Select-Object Name, Length, LastWriteTime |
    Export-Csv -Path "old-logs.csv" -NoTypeInformation

#endregion
