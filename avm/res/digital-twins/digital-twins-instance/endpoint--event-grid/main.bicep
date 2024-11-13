metadata name = 'Digital Twins Instance Event Grid Endpoints'
metadata description = 'This module deploys a Digital Twins Instance Event Grid Endpoint.'
metadata owner = 'Azure/module-maintainers'

@description('Required. EventGrid Topic Endpoint.')
param eventGrid endpointResourceType

@description('Conditional. The name of the parent Digital Twin Instance resource. Required if the template is used in a standalone deployment.')
param digitalTwinInstanceName string

@description('Required. The resource ID of the Event Grid to get access keys from.')
param eventGridDomainResourceId string

resource digitalTwinsInstance 'Microsoft.DigitalTwins/digitalTwinsInstances@2023-01-31' existing = {
  name: digitalTwinInstanceName
}

// workaround for https://github.com/Azure/bicep-types-az/issues/2262
resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' existing = {
  name: eventGrid.topicEndpoint
}

resource endpoint 'Microsoft.DigitalTwins/digitalTwinsInstances/endpoints@2023-01-31' = {
  name: eventGrid.name ?? 'EventGridEndpoint'
  parent: digitalTwinsInstance
  properties: {
    endpointType: 'EventGrid'
    authenticationType: 'KeyBased'
    TopicEndpoint: eventGridTopic.name
    accessKey1: listkeys(eventGridDomainResourceId, '2022-06-15').key1
    accessKey2: listkeys(eventGridDomainResourceId, '2022-06-15').key2
    deadLetterSecret: eventGrid.deadLetterSecret
    deadLetterUri: eventGrid.deadLetterUri
  }
}

@description('The resource ID of the Endpoint.')
output resourceId string = endpoint.id

@description('The name of the resource group the resource was created in.')
output resourceGroupName string = resourceGroup().name

@description('The name of the Endpoint.')
output name string = endpoint.name

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

  @description('Required. The EventGrid Topic Endpoint.')
  topicEndpoint: string

  @description('Required. EventGrid first accesskey.')
  accessKey1: string

  @description('Optional. EventGrid second accesskey.')
  accessKey2: string?
}
