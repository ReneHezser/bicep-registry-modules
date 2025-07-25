metadata name = 'Microsoft Entra Domain Services'
metadata description = 'This module deploys an Microsoft Entra Domain Services (Azure AD DS) instance.'

@minLength(1)
@maxLength(19) // 15 characters for domain name + 4 characters for the suffix
@description('Optional. The name of the Azure AD DS resource. Defaults to the domain name specific to the Azure AD DS service. The prefix of your specified domain name (such as dscontoso in the dscontoso.com domain name) must contain 15 or fewer characters.')
param name string = domainName

@description('Optional. The location to deploy the Azure AD DS Services. Uses the resource group location if not specified.')
param location string = resourceGroup().location

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

// ============ //
// Parameters   //
// ============ //

@minLength(1)
@metadata({
  example: '''
  - 'contoso.onmicrosoft.com'
  - 'aaddscontoso.com'
  '''
})
@description('Required. The domain name specific to the Azure AD DS service.')
param domainName string

@description('Optional. The name of the SKU specific to Azure AD DS Services. For replica set support, this defaults to Enterprise.')
@allowed([
  'Standard'
  'Enterprise'
  'Premium'
])
param sku string = 'Enterprise'

@description('Optional. Additional replica set for the managed domain.')
param replicaSets replicaSetType[]?

@description('Conditional. The certificate required to configure Secure LDAP. Should be a base64encoded representation of the certificate PFX file and contain the domainName as CN. Required if secure LDAP is enabled and must be valid more than 30 days.')
@secure()
param pfxCertificate string = ''

@description('Conditional. The password to decrypt the provided Secure LDAP certificate PFX file. Required if secure LDAP is enabled.')
@secure()
param pfxCertificatePassword string = ''

@metadata({
  example: '''
  - ['john@doh.org']
  - ['john@doh.org','jane@doh.org']
  '''
})
@description('Optional. The email recipient value to receive alerts.')
param additionalRecipients array = []

@description('Optional. The value is to provide domain configuration type.')
@allowed([
  'FullySynced'
  'ResourceTrusting'
])
param domainConfigurationType string = 'FullySynced'

@description('Optional. The value is to synchronize scoped users and groups.')
@allowed([
  'Disabled'
  'Enabled'
])
param filteredSync string = 'Enabled'

@description('Optional. The value is to enable clients making request using TLSv1.')
@allowed([
  'Enabled'
  'Disabled'
])
param tlsV1 string = 'Disabled'

@description('Optional. The value is to enable clients making request using NTLM v1.')
@allowed([
  'Enabled'
  'Disabled'
])
param ntlmV1 string = 'Disabled'

@description('Optional. The value is to enable synchronized users to use NTLM authentication.')
@allowed([
  'Enabled'
  'Disabled'
])
#disable-next-line secure-secrets-in-params // Not a secret
param syncNtlmPasswords string = 'Enabled'

@description('Optional. The value is to enable on-premises users to authenticate against managed domain.')
@allowed([
  'Enabled'
  'Disabled'
])
#disable-next-line secure-secrets-in-params // Not a secret
param syncOnPremPasswords string = 'Enabled'

@description('Optional. The value is to enable Kerberos requests that use RC4 encryption.')
@allowed([
  'Enabled'
  'Disabled'
])
param kerberosRc4Encryption string = 'Disabled'

@description('Optional. The value is to enable to provide a protected channel between the Kerberos client and the KDC.')
@allowed([
  'Enabled'
  'Disabled'
])
param kerberosArmoring string = 'Enabled'

@description('Optional. The value is to notify the DC Admins.')
@allowed([
  'Enabled'
  'Disabled'
])
param notifyDcAdmins string = 'Enabled'

@description('Optional. The value is to notify the Global Admins.')
@allowed([
  'Enabled'
  'Disabled'
])
param notifyGlobalAdmins string = 'Enabled'

@description('Optional. The value is to enable the Secure LDAP for external services of Azure AD DS Services.')
@allowed([
  'Enabled'
  'Disabled'
])
param externalAccess string = 'Enabled'

@description('Optional. A flag to determine whether or not Secure LDAP is enabled or disabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param ldaps string = 'Enabled'

@description('Optional. All users in AAD are synced to AAD DS domain or only users actively syncing in the cloud. Defaults to All.')
@allowed(['All', 'CloudOnly'])
param syncScope string = 'All'

import { diagnosticSettingFullType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingFullType[]?

@metadata({
  example: '''
  {
      "key1": "value1",
      "key2": "value2"
  }
  '''
})
@description('Optional. Tags of the resource.')
param tags resourceInput<'Microsoft.AAD/domainServices@2022-12-01'>.tags?

import { lockType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalIds\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments roleAssignmentType[]?

@description('Generated. Built-in roles "General": https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#general.')
var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

var formattedRoleAssignments = [
  for (roleAssignment, index) in (roleAssignments ?? []): union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]

// ============== //
// Resources      //
// ============== //

#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.aad-domainservice.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://aka.ms/avm/TelemetryInfo'
        }
      }
    }
  }
}

resource domainservice 'Microsoft.AAD/domainServices@2022-12-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    domainName: domainName
    domainConfigurationType: domainConfigurationType
    filteredSync: filteredSync
    notificationSettings: {
      additionalRecipients: additionalRecipients
      notifyDcAdmins: notifyDcAdmins
      notifyGlobalAdmins: notifyGlobalAdmins
    }
    ldapsSettings: {
      externalAccess: externalAccess
      ldaps: ldaps
      pfxCertificate: !empty(pfxCertificate) ? pfxCertificate : null
      pfxCertificatePassword: !empty(pfxCertificatePassword) ? pfxCertificatePassword : null
    }
    replicaSets: replicaSets
    domainSecuritySettings: {
      tlsV1: tlsV1
      ntlmV1: ntlmV1
      syncNtlmPasswords: syncNtlmPasswords
      syncOnPremPasswords: syncOnPremPasswords
      kerberosRc4Encryption: kerberosRc4Encryption
      kerberosArmoring: kerberosArmoring
    }
    sku: sku
    syncScope: syncScope
  }
}

resource domainservice_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (diagnosticSetting, index) in (diagnosticSettings ?? []): {
    name: diagnosticSetting.?name ?? '${name}-diagnosticSettings'
    properties: {
      storageAccountId: diagnosticSetting.?storageAccountResourceId
      workspaceId: diagnosticSetting.?workspaceResourceId
      eventHubAuthorizationRuleId: diagnosticSetting.?eventHubAuthorizationRuleResourceId
      eventHubName: diagnosticSetting.?eventHubName
      metrics: [
        for group in (diagnosticSetting.?metricCategories ?? [{ category: 'AllMetrics' }]): {
          category: group.category
          enabled: group.?enabled ?? true
          timeGrain: null
        }
      ]
      logs: [
        for group in (diagnosticSetting.?logCategoriesAndGroups ?? [{ categoryGroup: 'allLogs' }]): {
          categoryGroup: group.?categoryGroup
          category: group.?category
          enabled: group.?enabled ?? true
        }
      ]
      marketplacePartnerId: diagnosticSetting.?marketplacePartnerResourceId
      logAnalyticsDestinationType: diagnosticSetting.?logAnalyticsDestinationType
    }
    scope: domainservice
  }
]

resource domainservice_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.'
  }
  scope: domainservice
}

resource domainservice_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(domainservice.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: domainservice
  }
]

// ============ //
// Outputs      //
// ============ //

@description('The domain name of the Microsoft Entra Domain Services(Azure AD DS).')
output name string = domainservice.name

@description('The name of the resource group the Microsoft Entra Domain Services(Azure AD DS) was created in.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the Microsoft Entra Domain Services(Azure AD DS).')
output resourceId string = domainservice.id

@description('The location the resource was deployed into.')
output location string = domainservice.location

// ================ //
// Definitions      //
// ================ //

@export()
@description('The type of the replica set.')
type replicaSetType = {
  @description('Required. Virtual network location.')
  location: string

  @metadata({
    example: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<resourceGroup>/providers/Microsoft.Network/virtualNetworks/<vnetName>/subnets/<subnetName>'
  })
  @description('Required. The id of the subnet that Domain Services will be deployed on. The subnet has some requirements, which are outlined in the [notes section](#Network-Security-Group-NSG-requirements-for-AADDS) of the documentation.')
  subnetId: string
}
