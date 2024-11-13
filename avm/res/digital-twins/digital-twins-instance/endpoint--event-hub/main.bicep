metadata name = 'Digital Twins Instance EventHub Endpoint'
metadata description = 'This module deploys a Digital Twins Instance EventHub Endpoint.'
metadata owner = 'Azure/module-maintainers'

@description('Optional. The name of the Digital Twin Endpoint.')
param name string = 'EventHubEndpoint'

@description('Required. Event Hub Endpoint.')
param eventHub endpointResourceType

@description('Conditional. The name of the parent Digital Twin Instance resource. Required if the template is used in a standalone deployment.')
param digitalTwinInstanceName string

// @allowed([
//   'IdentityBased'
//   'KeyBased'
// ])
// @description('Optional. Specifies the authentication type being used for connecting to the endpoint. If \'KeyBased\' is selected, a connection string must be specified (at least the primary connection string). If \'IdentityBased\' is selected, the endpointUri and entityPath properties must be specified.')
// param authenticationType string = 'IdentityBased'

// @description('Conditional. Dead letter storage secret for key-based authentication. Will be obfuscated during read. Required if the `authenticationType` is "KeyBased".')
// @secure()
// param deadLetterSecret string = ''

// @description('Conditional. Dead letter storage URL for identity-based authentication. Required if the `authenticationType` is "IdentityBased".')
// param deadLetterUri string = ''

// @description('Conditional. PrimaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read. Required if the `authenticationType` is "KeyBased".')
// @secure()
// param connectionStringPrimaryKey string = ''

// @description('Conditional. SecondaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read. Only used if the `authenticationType` is "KeyBased".')
// @secure()
// param connectionStringSecondaryKey string = ''

// @description('Conditional. The EventHub name in the EventHub namespace for identity-based authentication. Required if the `authenticationType` is "IdentityBased".')
// param entityPath string = ''

// @description('Conditional. The URL of the EventHub namespace for identity-based authentication. It must include the protocol \'sb://\' (i.e. sb://xyz.servicebus.windows.net). Required if the `authenticationType` is "IdentityBased".')
// param endpointUri string = ''

// import { managedIdentityAllType } from 'br/public:avm/utl/types/avm-common-types:0.3.0'
// @description('Optional. The managed identity definition for this resource.  Only one type of identity is supported: system-assigned or user-assigned, but not both.')
// param managedIdentities managedIdentityAllType?

var identity = !empty(eventHub.identity)
  ? {
      type: (eventHub.?identity.?systemAssigned ?? false)
        ? 'SystemAssigned'
        : (!empty(eventHub.?identity.?userAssignedResourceId ?? '') ? 'UserAssigned' : null)
      userAssignedIdentity: eventHub.?identity.?userAssignedResourceId
    }
  : null

resource digitalTwinsInstance 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' existing = {
  name: digitalTwinInstanceName
}

resource endpoint 'Microsoft.DigitalTwins/digitalTwinsInstances/endpoints@2023-01-31' = {
  name: name
  parent: digitalTwinsInstance
  properties: {
    endpointType: 'EventHub'
    authenticationType: eventHub.authenticationType
    connectionStringPrimaryKey: eventHub.connectionStringPrimaryKey
    connectionStringSecondaryKey: eventHub.connectionStringSecondaryKey
    deadLetterSecret: eventHub.deadLetterSecret
    deadLetterUri: eventHub.deadLetterUri
    endpointUri: eventHub.endpointUri
    entityPath: eventHub.name
    identity: identity
  }
}

@description('The resource ID of the Endpoint.')
output resourceId string = endpoint.id

@description('The name of the resource group the resource was created in.')
output resourceGroupName string = resourceGroup().name

@description('The name of the Endpoint.')
output name string = endpoint.name

@description('The principal ID of the system assigned identity. Note: As of 2024-03 is not exported by API.')
#disable-next-line BCP187
output systemAssignedMIPrincipalId string = endpoint.?identity.?principalId ?? ''

// =============== //
//   Definitions   //
// =============== //

import { managedIdentityAllType } from 'br/public:avm/utl/types/avm-common-types:0.3.0'

@description('Optional. Connection information for the endpoint, to which data is sent.')
@export()
type endpointResourceType = {
  @description('Required. The name of endpoint.')
  name: string

  @description('Required. Specifies the authentication type being used for connecting to the endpoint. Possible values are "KeyBased" or "IdentityBased".')
  authenticationType: string

  @description('Conditional. Dead letter storage secret for key-based authentication. Will be obfuscated during read. Required if the `authenticationType` is "KeyBased".')
  deadLetterSecret: string?

  @description('Conditional. Dead letter storage URL for identity-based authentication. Required if the `authenticationType` is "IdentityBased".')
  deadLetterUri: string?

  @description('Conditional. The EventHub name in the EventHub namespace for identity-based authentication. Required if the `authenticationType` is "IdentityBased".')
  identity: managedIdentityAllType?

  @description('Required. PrimaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read. Required if the `authenticationType` is "KeyBased".')
  connectionStringPrimaryKey: string?

  @description('Conditional. SecondaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read. Only used if the `authenticationType` is "KeyBased".')
  connectionStringSecondaryKey: string?

  @description('Conditional. The URL of the EventHub namespace for identity-based authentication. It must include the protocol \'sb://\' (i.e. sb://xyz.servicebus.windows.net). Required if the `authenticationType` is "IdentityBased".')
  endpointUri: string?

  @description('Conditional. The EventHub name in the EventHub namespace for identity-based authentication. Required if the `authenticationType` is "IdentityBased".')
  entityPath: string?
}
