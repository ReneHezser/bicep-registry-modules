metadata name = 'Network Watchers'
metadata description = 'This module deploys a Network Watcher.'

@description('Optional. Name of the Network Watcher resource (hidden).')
@minLength(1)
param name string = 'NetworkWatcher_${location}'

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Array that contains the Connection Monitors.')
param connectionMonitors array = []

@description('Optional. Array that contains the Flow Logs.')
param flowLogs array = []

import { lockType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

@description('Optional. Tags of the resource.')
param tags object?

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Network Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4d97b98b-1d4f-4787-a291-c67834d212e7'
  )
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

#disable-next-line no-deployments-resources
resource avmTelemetry 'Microsoft.Resources/deployments@2024-03-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.network-networkwatcher.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
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

resource networkWatcher 'Microsoft.Network/networkWatchers@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
}

resource networkWatcher_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.'
  }
  scope: networkWatcher
}

resource networkWatcher_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(networkWatcher.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: networkWatcher
  }
]

module networkWatcher_connectionMonitors 'connection-monitor/main.bicep' = [
  for (connectionMonitor, index) in connectionMonitors: {
    name: '${uniqueString(deployment().name, location)}-NW-ConnectionMonitor-${index}'
    params: {
      tags: tags
      endpoints: connectionMonitor.?endpoints ?? []
      name: connectionMonitor.name
      location: location
      networkWatcherName: networkWatcher.name
      testConfigurations: connectionMonitor.?testConfigurations ?? []
      testGroups: connectionMonitor.?testGroups ?? []
      workspaceResourceId: connectionMonitor.?workspaceResourceId ?? ''
    }
  }
]

module networkWatcher_flowLogs 'flow-log/main.bicep' = [
  for (flowLog, index) in flowLogs: {
    name: '${uniqueString(deployment().name, location)}-NW-FlowLog-${index}'
    params: {
      tags: tags
      enabled: flowLog.?enabled ?? true
      formatVersion: flowLog.?formatVersion ?? 2
      location: flowLog.?location ?? location
      name: flowLog.?name ?? '${last(split(flowLog.targetResourceId, '/'))}-${split(flowLog.targetResourceId, '/')[4]}-flowlog'
      networkWatcherName: networkWatcher.name
      retentionInDays: flowLog.?retentionInDays ?? 365
      storageId: flowLog.storageId
      targetResourceId: flowLog.targetResourceId
      trafficAnalyticsInterval: flowLog.?trafficAnalyticsInterval ?? 60
      workspaceResourceId: flowLog.?workspaceResourceId ?? ''
    }
  }
]

@description('The name of the deployed network watcher.')
output name string = networkWatcher.name

@description('The resource ID of the deployed network watcher.')
output resourceId string = networkWatcher.id

@description('The resource group the network watcher was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = networkWatcher.location
