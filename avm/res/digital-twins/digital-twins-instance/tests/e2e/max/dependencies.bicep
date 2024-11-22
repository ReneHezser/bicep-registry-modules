@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

@description('Required. The name of the Virtual Network to create.')
param virtualNetworkName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the Event Hub Namespace to create.')
param eventHubNamespaceName string

@description('Required. The name of the Event Hub to create.')
param eventHubName string

@description('Required. Service Bus name')
param serviceBusName string

@description('Required. Event Grid Domain name.')
param eventGridDomainName string

@description('Required. Event Grid Topic name.')
param eventGridTopicName string

var addressPrefix = '10.0.0.0/16'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'defaultSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 16, 0)
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.digitaltwins.azure.net'
  location: 'global'

  resource virtualNetworkLinks 'virtualNetworkLinks@2024-06-01' = {
    name: '${virtualNetwork.name}-vnetlink'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubNamespaceName
  location: location
  properties: {
    zoneRedundant: false
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }

  // resource eventHub 'eventhubs@2024-01-01' = {
  //   name: eventHubName
  // }
}
resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  name: eventHubName
  parent: eventHubNamespace
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: serviceBusName
  location: location
  properties: {
    zoneRedundant: false
  }

  resource topic 'topics@2024-01-01' = {
    name: 'topic'
  }
}

resource eventGridDomain 'Microsoft.EventGrid/domains@2022-06-15' = {
  name: eventGridDomainName
  location: location
  properties: {
    disableLocalAuth: false
  }
}
resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: eventGridTopicName
  location: location
}

resource eventHubNamespaceRbacAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, 'evhrbacAssignment')
  scope: eventHubNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '2b629674-e913-4c01-ae53-ef4638d8f975'
    ) //Azure Event Hubs Data Sender
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusRbacAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, 'sbrbacAssignment')
  scope: serviceBus
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
    ) //Azure Service Bus Data Sender
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The resource ID of the created Virtual Network Subnet.')
output subnetResourceId string = virtualNetwork.properties.subnets[0].id

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Private DNS Zone.')
output privateDNSZoneResourceId string = privateDNSZone.id

@description('The name of the Event Hub Namespace.')
output eventhubNamespaceName string = eventHubNamespace.name

@description('The resource ID of the created Event Hub Namespace.')
output eventHubResourceId string = eventHub.id // eventHubNamespace::eventHub.id

@description('The name of the Event Hub.')
output eventhubName string = eventHub.name // eventHubNamespace::eventHub.name

@description('The name of the Service Bus Namespace.')
output serviceBusName string = serviceBus.name

@description('The name of the Service Bus Topic.')
output serviceBusTopicName string = serviceBus::topic.name

@description('The Event Grid Topic endpoint uri.')
output eventGridTopicEndpoint string = eventGridTopic.properties.endpoint

@description('The resource ID of the created Event Grid Topic.')
output eventGridTopicResourceId string = eventGridTopic.id

@description('The name of the Event Grid Topic.')
output eventGridTopicName string = eventGridTopic.name

@description('The resource ID of the created Event Grid Domain.')
output eventGridDomainResourceId string = eventGridDomain.id

@description('The resource ID of the created Managed Identity.')
output managedIdentityResourceId string = managedIdentity.id
