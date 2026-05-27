<#
.SYNOPSIS
    End-to-end deployment script for Foundry Slim.
    Creates resource group, Entra ID groups, and deploys all Bicep resources.

.PARAMETER ResourceGroupName
    Name of the resource group to create/use.

.PARAMETER Location
    Azure region for all resources.

.PARAMETER ProjectName
    Short identifier for the first project (max 12 chars).

.PARAMETER Project2Name
    Short identifier for the second project (max 12 chars).

.PARAMETER BusinessUnit
    Business unit code for cost tagging and resource naming.

.PARAMETER CostCenter
    Finance allocation code.

.PARAMETER OwnerEmail
    Email address for budget alert notifications.

.PARAMETER MonthlyBudget
    Monthly budget amount in USD (default: 500).

.PARAMETER EnvironmentTag
    Environment tag: dev, experimental, or poc (default: dev).

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName 'myorg-foundry-eastus2' -Location 'eastus2' `
        -ProjectName 'aiteam01' -Project2Name 'aiteam02' `
        -BusinessUnit 'myorg-eastus2' -CostCenter 'myorg-eastus2-cs-001' `
        -OwnerEmail 'admin@contoso.onmicrosoft.com'
#>

param(
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $Location,
    [Parameter(Mandatory)] [string] $ProjectName,
    [Parameter(Mandatory)] [string] $Project2Name,
    [Parameter(Mandatory)] [string] $BusinessUnit,
    [Parameter(Mandatory)] [string] $CostCenter,
    [Parameter(Mandatory)] [string] $OwnerEmail,
    [int]    $MonthlyBudget = 500,
    [ValidateSet('dev','experimental','poc')]
    [string] $EnvironmentTag = 'dev'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-EntraGroupIfNotExists {
    param([string]$DisplayName, [string]$Description)

    $existing = az ad group list --display-name $DisplayName --query "[?displayName=='$DisplayName'].id" -o tsv 2>$null
    if ($existing) {
        Write-Host "  Group '$DisplayName' already exists: $existing" -ForegroundColor Yellow
        return $existing
    }

    Write-Host "  Creating group '$DisplayName'..." -ForegroundColor Cyan
    $id = az ad group create `
        --display-name $DisplayName `
        --mail-nickname ($DisplayName -replace '\s','') `
        --description $Description `
        --query id -o tsv

    if (-not $id) { throw "Failed to create Entra ID group '$DisplayName'" }
    Write-Host "  Created: $id" -ForegroundColor Green
    return $id
}

# ── Step 1: Create Resource Group ────────────────────────────────────────────
Write-Host "`n=== Step 1: Resource Group ===" -ForegroundColor Magenta
$rgExists = az group exists --name $ResourceGroupName -o tsv
if ($rgExists -eq 'true') {
    Write-Host "  Resource group '$ResourceGroupName' already exists." -ForegroundColor Yellow
} else {
    Write-Host "  Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
    az group create --name $ResourceGroupName --location $Location --output none
    Write-Host "  Created." -ForegroundColor Green
}

# ── Step 2: Create Entra ID Groups ──────────────────────────────────────────
Write-Host "`n=== Step 2: Entra ID Groups ===" -ForegroundColor Magenta

$groupPrefix = $ResourceGroupName

$accountOwnerGroupId = New-EntraGroupIfNotExists `
    -DisplayName "$groupPrefix-account-owners" `
    -Description "Azure AI Administrator on the Foundry account for $groupPrefix"

$project1DevGroupId = New-EntraGroupIfNotExists `
    -DisplayName "$groupPrefix-$ProjectName-developers" `
    -Description "Azure AI Developer for $ProjectName project in $groupPrefix"

$project2DevGroupId = New-EntraGroupIfNotExists `
    -DisplayName "$groupPrefix-$Project2Name-developers" `
    -Description "Azure AI Developer for $Project2Name project in $groupPrefix"

$subAdminGroupId = New-EntraGroupIfNotExists `
    -DisplayName "$groupPrefix-subscription-admins" `
    -Description "Contributor at subscription scope for $groupPrefix"

Write-Host "`n  Group IDs:" -ForegroundColor White
Write-Host "    Account Owners:     $accountOwnerGroupId"
Write-Host "    Project 1 Devs:     $project1DevGroupId"
Write-Host "    Project 2 Devs:     $project2DevGroupId"
Write-Host "    Subscription Admin: $subAdminGroupId"

# ── Step 3: Deploy Bicep ────────────────────────────────────────────────────
Write-Host "`n=== Step 3: Bicep Deployment ===" -ForegroundColor Magenta
Write-Host "  Deploying to '$ResourceGroupName'..." -ForegroundColor Cyan

az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "$PSScriptRoot\main.bicep" `
    --parameters "$PSScriptRoot\main.bicepparam" `
    --parameters `
        accountOwnerGroupObjectId=$accountOwnerGroupId `
        project1DevGroupObjectId=$project1DevGroupId `
        project2DevGroupObjectId=$project2DevGroupId `
        subscriptionAdminGroupObjectId=$subAdminGroupId `
        location=$Location `
        projectName=$ProjectName `
        project2Name=$Project2Name `
        businessUnit=$BusinessUnit `
        costCenter=$CostCenter `
        ownerEmail=$OwnerEmail `
        monthlyBudget=$MonthlyBudget `
        environmentTag=$EnvironmentTag

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n  Deployment FAILED." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "  Resource Group:  $ResourceGroupName"
Write-Host "  Foundry Account: az resource list -g $ResourceGroupName --resource-type Microsoft.CognitiveServices/accounts -o table"
Write-Host ""
