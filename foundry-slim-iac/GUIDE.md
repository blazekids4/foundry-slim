# Foundry Slim — Plain-Language Guide

This document explains what each file does, what gets deployed, and what permissions each role grants — written for anyone, not just engineers.

---

## What This Project Does

This project creates an **AI Foundry environment** in Azure — a workspace where teams can build AI agents and applications using models like GPT-4.1, GPT-5, and others. It sets up:

- The AI platform itself (Foundry account + two team projects)
- AI models ready to use (chat, reasoning, code generation, image generation, embeddings)
- Monitoring (so you can see what's happening and troubleshoot)
- Security groups (so the right people have the right access)
- A spending cap (budget alerts at 80% and 100%)

Everything is automated through a single PowerShell script.

---

## Files Explained

### `deploy.ps1` — The Deployment Script

**What it does:** This is the only file you run. It handles everything in order:

1. Creates the Azure resource group (a container for all the resources)
2. Creates four security groups in Entra ID (Microsoft's identity system)
3. Deploys all the infrastructure using the Bicep templates below

**Think of it as:** The installer. You run it once, answer no questions, and everything gets built.

---

### `main.bicep` — The Master Blueprint

**What it does:** This is the orchestrator that calls all the module files below in the correct order. It defines:

- What parameters the deployment accepts (region, project names, budget, etc.)
- How resources are named (using the `businessUnit` parameter + a unique suffix)
- What tags get applied to all resources for cost tracking
- The order things get built (Foundry first, then monitoring, then security, then budget)

**Think of it as:** The table of contents that tells Azure "build these things in this order."

---

### `main.bicepparam` — The Configuration Values

**What it does:** Contains the actual values used during deployment:

- **Location:** `eastus2` (the Azure data center region)
- **Project names:** `aiteam01` and `aiteam02`
- **Business unit:** `myorg-eastus2` (used in resource naming and cost tags)
- **Budget:** $500/month with email alerts
- **Model list:** Which AI models to deploy and how much capacity each gets

**Think of it as:** The order form — it fills in the blanks in the blueprint.

---

### `modules/ai-foundry.bicep` — The AI Platform

**What it creates:**

| Resource | What It Is |
|---|---|
| **AI Foundry Account** | The top-level AI platform. This is an Azure AI Services resource with project management enabled. It hosts all models and provides the API endpoint. |
| **Project 1** (`aiteam01`) | A workspace for Team 1. Projects isolate each team's files, agents, and outputs. |
| **Project 2** (`aiteam02`) | A workspace for Team 2, completely separate from Team 1. |
| **Model Deployments** | The AI models made available through the Foundry endpoint (see model table below). |

---

### `modules/observability.bicep` — Monitoring

**What it creates:**

| Resource | What It Is |
|---|---|
| **Log Analytics Workspace** | A database that collects logs and metrics from all resources. You can query it to troubleshoot issues or analyze usage. |
| **Application Insights** | A monitoring dashboard built on top of Log Analytics. Shows request rates, failures, response times, and traces for AI model calls. |
| **Diagnostic Settings** | A pipeline that automatically sends Foundry account logs and metrics to Log Analytics. Without this, no telemetry would be captured. |

---

### `modules/foundry-connection.bicep` — Wiring Monitoring to Foundry

**What it creates:** A connection inside the Foundry account that links Application Insights to the Foundry portal. This enables tracing — when an agent makes a model call, you can see the full request/response chain in the Foundry UI.

---

### `modules/rbac-account-owner-group.bicep` — Account Owner Permissions

**What it creates:** A role assignment that gives the **Account Owners** security group the **Azure AI Administrator** role on the Foundry account.

#### What Account Owners CAN do:
- Create, modify, and delete projects
- Deploy and manage AI models
- Create and manage connections to other services
- View all resources and configurations
- Manage access for other users within Foundry

#### What Account Owners CANNOT do:
- Delete the Foundry account itself (requires subscription-level access)
- Manage Azure resources outside of Foundry (VMs, storage, networking, etc.)
- Assign Azure-level roles to other users (requires Owner or User Access Administrator)

---

### `modules/rbac-project-dev-group.bicep` — Developer Permissions

**What it creates:** A role assignment that gives a team's security group the **Azure AI Developer** role on their specific project. This module is called twice — once for Team 1, once for Team 2.

#### What Developers CAN do:
- Use the AI models (send prompts, get responses)
- Create and run agents within their project
- Upload and manage files in their project
- View their project's connections and configurations
- Access playground and testing tools

#### What Developers CANNOT do:
- Access the other team's project
- Deploy or delete AI models
- Create or modify Foundry connections
- Change account-level settings
- Manage other users' permissions

---

### `modules/rbac-subscription-admin.bicep` — Subscription Admin Permissions

**What it creates:** A role assignment that gives the **Subscription Admins** group the **Contributor** role at the entire Azure subscription level.

#### What Subscription Admins CAN do:
- Create, modify, and delete any Azure resource in the subscription
- Deploy new resource groups and services
- View all resources, costs, and configurations
- Manage networking, storage, compute, and all other Azure services

#### What Subscription Admins CANNOT do:
- Assign roles to other users (requires Owner role)
- Manage Azure Policy or Blueprints
- Change subscription-level billing or enrollment settings

---

### `modules/budget.bicep` — Spending Alerts

**What it creates:** A budget monitor on the resource group with two alert thresholds:

| Threshold | What Happens |
|---|---|
| **80% ($400)** | Sends an email to the owner warning that spending is approaching the limit |
| **100% ($500)** | Sends an email that the budget has been reached |

**Important:** Budget alerts are notifications only — they do NOT stop resources from running. Resources will continue to incur costs past the budget limit.

---

## AI Models Deployed

Each model is deployed at 25% of the subscription's maximum quota to leave room for other deployments.

### Standard (Regional — eastus2)
Your data stays in the East US 2 data center.

| Model | What It's For | Capacity |
|---|---|---|
| `gpt-4.1` | General-purpose chat and reasoning | 250K TPM |
| `o4-mini` | Fast reasoning tasks | 250K TPM |
| `text-embedding-3-large` | Converting text to vectors for search/similarity | 87K TPM |

### DataZoneStandard (US Data Zone)
Your data stays within the United States but may move between US data centers.

| Model | What It's For | Capacity |
|---|---|---|
| `gpt-5-mini` | Latest generation, balanced cost/performance | 75K TPM |
| `gpt-5-nano` | Ultra-fast, lowest cost per token | 500K TPM |
| `o3` | Advanced reasoning and analysis | 75K TPM |
| `gpt-image-1.5` | Image generation | 1 concurrent request |
| `text-embedding-3-small` | Lightweight embeddings | 250K TPM |
| `text-embedding-3-large` | High-quality embeddings | 250K TPM |

### GlobalStandard (Global)
Your data may be processed in any Microsoft data center worldwide. Offers highest availability.

| Model | What It's For | Capacity |
|---|---|---|
| `gpt-5.3-chat` | Latest chat model, highest quality | 250K TPM |
| `gpt-5.3-codex` | Code generation and analysis | 250K TPM |
| `gpt-5.1-codex-mini` | Lightweight code generation | 250K TPM |

> **TPM** = Tokens Per Minute (measured in thousands). A token is roughly ¾ of a word. 250K TPM means the model can process about 187,500 words per minute.

---

## Security Groups Created

The deployment script creates four Entra ID security groups. Add users to these groups to grant them the corresponding access level.

| Group Name | Purpose | How to Add Members |
|---|---|---|
| `myorg-foundry-eastus2-account-owners` | Full admin on the Foundry account | Azure Portal > Entra ID > Groups |
| `myorg-foundry-eastus2-aiteam01-developers` | Developer access to Project 1 only | Azure Portal > Entra ID > Groups |
| `myorg-foundry-eastus2-aiteam02-developers` | Developer access to Project 2 only | Azure Portal > Entra ID > Groups |
| `myorg-foundry-eastus2-subscription-admins` | Full resource management on the subscription | Azure Portal > Entra ID > Groups |

---

## How to Deploy

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

**Prerequisites:**
- Azure CLI installed and logged in (`az login`)
- Permissions to create resource groups, Entra ID groups, and role assignments
- Sufficient model quota in your subscription
