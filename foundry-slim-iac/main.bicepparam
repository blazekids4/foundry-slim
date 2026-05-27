using 'main.bicep'

// These values are overridden by deploy.ps1 at runtime.
// To deploy manually, replace the placeholder GUIDs below.

param location = 'eastus2'
param projectName = 'aiteam01'
param project2Name = 'aiteam02'

// Entra ID group identifiers — created automatically by deploy.ps1
param accountOwnerGroupObjectId = '00000000-0000-0000-0000-000000000000'
param project1DevGroupObjectId = '00000000-0000-0000-0000-000000000000'
param project2DevGroupObjectId = '00000000-0000-0000-0000-000000000000'
param subscriptionAdminGroupObjectId = '00000000-0000-0000-0000-000000000000'

// Tagging
param environmentTag = 'dev'
param businessUnit = 'myorg-eastus2'
param costCenter = 'myorg-eastus2-cs-001'

// Budget
param ownerEmail = 'admin@contoso.onmicrosoft.com'
param monthlyBudget = 500

// Model deployments
// deploymentName = unique ARM deployment name; name = actual model identifier
// capacity = 25% of subscription quota max (in K TPM unless noted)
param modelDeployments = [
  // --- Standard (eastus2 region) ---
  //                                                                                                                          Max     25%
  { deploymentName: 'gpt-4-1',                       name: 'gpt-4.1',                format: 'OpenAI', version: '2025-04-14', skuName: 'Standard',         capacity: 250 }   // uncapped → 250
  { deploymentName: 'o4-mini',                        name: 'o4-mini',                 format: 'OpenAI', version: '2025-04-16', skuName: 'Standard',         capacity: 250 }   // 1000 → 250
  { deploymentName: 'text-embedding-3-large',         name: 'text-embedding-3-large',  format: 'OpenAI', version: '1',          skuName: 'Standard',         capacity: 87 }    // 350 → 87

  // --- DataZoneStandard (US Data Zone) ---
  { deploymentName: 'gpt-5-mini-dz',                 name: 'gpt-5-mini',              format: 'OpenAI', version: '2025-08-07', skuName: 'DataZoneStandard', capacity: 75 }    // 300 → 75
  { deploymentName: 'gpt-5-nano-dz',                 name: 'gpt-5-nano',              format: 'OpenAI', version: '2025-08-07', skuName: 'DataZoneStandard', capacity: 500 }   // 2000 → 500
  { deploymentName: 'o3-dz',                          name: 'o3',                      format: 'OpenAI', version: '2025-04-16', skuName: 'DataZoneStandard', capacity: 75 }    // 300 → 75
  { deploymentName: 'gpt-image-1-5-dz',              name: 'gpt-image-1.5',           format: 'OpenAI', version: '2025-12-16', skuName: 'DataZoneStandard', capacity: 1 }     // 3 → 1 (concurrent requests)
  { deploymentName: 'text-embedding-3-small-dz',     name: 'text-embedding-3-small',  format: 'OpenAI', version: '1',          skuName: 'DataZoneStandard', capacity: 250 }   // 1000 → 250
  { deploymentName: 'text-embedding-3-large-dz',     name: 'text-embedding-3-large',  format: 'OpenAI', version: '1',          skuName: 'DataZoneStandard', capacity: 250 }   // 1000 → 250

  // --- GlobalStandard ---
  { deploymentName: 'gpt-5-3-chat-gs',               name: 'gpt-5.3-chat',            format: 'OpenAI', version: '2026-03-03', skuName: 'GlobalStandard',   capacity: 250 }   // 1000 → 250
  { deploymentName: 'gpt-5-3-codex-gs',              name: 'gpt-5.3-codex',           format: 'OpenAI', version: '2026-02-24', skuName: 'GlobalStandard',   capacity: 250 }   // 1000 → 250
  { deploymentName: 'gpt-5-1-codex-mini-gs',         name: 'gpt-5.1-codex-mini',      format: 'OpenAI', version: '2025-11-13', skuName: 'GlobalStandard',   capacity: 250 }   // 1000 → 250
]
