# Foundry Slim — Minimal AI Foundry Deployment

A lightweight Infrastructure-as-Code package that gets developers started with Azure AI Foundry fast. Deploys an AI Foundry account, two team projects, model deployments, and Application Insights for observability — nothing extra.

## What's Included

| Resource | Purpose |
|---|---|
| AI Foundry Account (AIServices) | CognitiveServices account with `allowProjectManagement` |
| 2× Foundry Projects | Isolated project scopes for two teams |
| 15 Model Deployments | Standard, DataZoneStandard, and GlobalStandard SKUs |
| Log Analytics Workspace | Backend for Application Insights |
| Application Insights | Tracing and telemetry for Foundry |
| App Insights Foundry Connection | Wires App Insights into Foundry portal |
| Entra ID Groups (4×) | Account Owners, Project Devs, Subscription Admins — created by `deploy.ps1` |
| RBAC — Account Owner Group | Azure AI Administrator on Foundry account |
| RBAC — 2× Project Dev Groups | Azure AI Developer scoped per project |
| RBAC — Subscription Admin Group | Contributor at subscription scope |
| Resource Group Tags | BusinessUnit, AppName, Environment, CostCenter |
| Budget Alert | 80% and 100% threshold notifications |

## Model Deployments

15 models across three SKU tiers, each at 25% of subscription quota:

| SKU | Models |
|---|---|
| **Standard** (regional eastus2) | `gpt-4.1`, `o4-mini`, `text-embedding-3-large` |
| **DataZoneStandard** (US Data Zone) | `gpt-5.4`, `gpt-5-mini`, `gpt-5-nano`, `model-router`, `o3`, `gpt-image-1.5`, `text-embedding-3-small`, `text-embedding-3-large` |
| **GlobalStandard** | `gpt-5.3-chat`, `gpt-5.3-codex`, `gpt-5.1-codex-mini` |

## What's Not Included

This package intentionally omits connected resources to keep the footprint minimal:

- Azure AI Search, Blob Storage, Cosmos DB, Key Vault
- Bing Search (grounding)
- Capability Hosts and their service connections

Add these when your workload requires them.

## Deploy

The `deploy.ps1` script handles everything end-to-end: resource group creation, Entra ID group creation, and Bicep deployment.

### PowerShell (recommended)

```powershell
.\deploy.ps1 `
  -ResourceGroupName 'myorg-foundry-eastus2' `
  -Location 'eastus2' `
  -ProjectName 'aiteam01' `
  -Project2Name 'aiteam02' `
  -BusinessUnit 'myorg-eastus2' `
  -CostCenter 'myorg-eastus2-cs-001' `
  -OwnerEmail 'admin@contoso.onmicrosoft.com'
```

The script creates these Entra ID groups automatically:
- `myorg-foundry-eastus2-account-owners`
- `myorg-foundry-eastus2-aiteam01-developers`
- `myorg-foundry-eastus2-aiteam02-developers`
- `myorg-foundry-eastus2-subscription-admins`

### Manual (if groups already exist)

```powershell
az group create --name 'myorg-foundry-eastus2' --location 'eastus2'

az deployment group create `
  --resource-group 'myorg-foundry-eastus2' `
  --template-file 'main.bicep' `
  --parameters 'main.bicepparam' `
  --parameters accountOwnerGroupObjectId='<guid>' `
               project1DevGroupObjectId='<guid>' `
               project2DevGroupObjectId='<guid>' `
               subscriptionAdminGroupObjectId='<guid>'
```

## Files

| File | Purpose |
|---|---|
| `deploy.ps1` | End-to-end deployment script (RG + Entra groups + Bicep) |
| `main.bicep` | Orchestrator — wires all modules together |
| `main.bicepparam` | Default parameter values (overridden by `deploy.ps1`) |
| `modules/ai-foundry.bicep` | Foundry account, projects, model deployments |
| `modules/observability.bicep` | Log Analytics, App Insights, Foundry diagnostics |
| `modules/foundry-connection.bicep` | App Insights connection to Foundry |
| `modules/rbac-account-owner-group.bicep` | Azure AI Administrator role assignment |
| `modules/rbac-project-dev-group.bicep` | Azure AI Developer role assignment (per project) |
| `modules/rbac-subscription-admin.bicep` | Contributor at subscription scope |
| `modules/budget.bicep` | Budget alert with 80%/100% thresholds |

## API Version

Uses `2025-06-01` for CognitiveServices resources, aligned with the [official Microsoft Foundry quickstart samples](https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/00-basic).
