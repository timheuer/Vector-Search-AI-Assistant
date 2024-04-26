targetScope = 'resourceGroup'

@description('')
param location string = resourceGroup().location

@description('')
param principalId string

@description('')
param principalType string = "ServicePrincipal"

param containers array = [
      {
        name: 'system-prompt'
      }
      {
        name: 'memory-source'
      }
      {
        name: 'product-policy'
      }
    ]

param files array = [
      {
        name: 'retailassistant-default-txt'
        file: 'Default.txt'
        path: 'RetailAssistant/Default.txt'
        content: loadTextContent('../../SystemPrompts/RetailAssistant/Default.txt')
        container: 'system-prompt'
      }
      {
        name: 'retailassistant-limited-txt'
        file: 'Limited.txt'
        path: 'RetailAssistant/Limited.txt'
        content: loadTextContent('../../SystemPrompts/RetailAssistant/Limited.txt')
        container: 'system-prompt'
      }
      {
        name: 'summarizer-twowords-txt'
        file: 'TwoWords.txt'
        path: 'Summarizer/TwoWords.txt'
        content: loadTextContent('../../SystemPrompts/Summarizer/TwoWords.txt')
        container: 'system-prompt'
      }
      {
        name: 'acsmemorysourceconfig-json'
        file: 'ACSMemorySourceConfig.json'
        path: 'ACSMemorySourceConfig.json'
        content: loadTextContent('../../MemorySources/ACSMemorySourceConfig.json')
        container: 'memory-source'
      }
      {
        name: 'blobmemorysourceconfig-json'
        file: 'BlobMemorySourceConfig.json'
        path: 'BlobMemorySourceConfig.json'
        content: loadTextContent('../../MemorySources/BlobMemorySourceConfig.json')
        container: 'memory-source'
      }
      {
        name: 'return-policies-txt'
        file: 'return-policies.txt'
        path: 'return-policies.txt'
        content: loadTextContent('../../MemorySources/return-policies.txt')
        container: 'product-policy'
      }
      {
        name: 'shipping-policies-txt'
        file: 'shipping-policies.txt'
        path: 'shipping-policies.txt'
        content: loadTextContent('../../MemorySources/shipping-policies.txt')
        container: 'product-policy'
      }
    ]


resource storageAccount_1XR3Um8QY 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: toLower(take('storage${uniqueString(resourceGroup().id)}', 24))
  location: location
  tags: {
    'aspire-resource-name': 'storage'
  }
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobService_vTLU20GRg 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount_1XR3Um8QY
  name: 'default'
  properties: {
  }
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [
  for container in containers: {
    parent: blobService_vTLU20GRg
    name: container.name
  }
]

resource blobFiles 'Microsoft.Resources/deploymentScripts@2020-10-01' = [
  for file in files: {
    name: file.file
    location: location
    kind: 'AzureCLI'
    properties: {
      azCliVersion: '2.26.1'
      timeout: 'PT5M'
      retentionInterval: 'PT1H'
      environmentVariables: [
        {
          name: 'AZURE_STORAGE_ACCOUNT'
          value: storageAccount_1XR3Um8QY.name
        }
        {
          name: 'AZURE_STORAGE_KEY'
          secureValue: storageAccount_1XR3Um8QY.listKeys().keys[0].value
        }
      ]
      scriptContent: 'echo "${file.content}" > ${file.file} && az storage blob upload -f ${file.file} -c ${file.container} -n ${file.path}'
    }
    dependsOn: [ blobContainers ]
  }
]

resource roleAssignment_Gz09cEnxb 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount_1XR3Um8QY
  name: guid(storageAccount_1XR3Um8QY.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: principalId
    principalType: principalType
  }
}

resource roleAssignment_HRj6MDafS 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount_1XR3Um8QY
  name: guid(storageAccount_1XR3Um8QY.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalId: principalId
    principalType: principalType
  }
}

resource roleAssignment_r0wA6OpKE 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount_1XR3Um8QY
  name: guid(storageAccount_1XR3Um8QY.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88'))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
    principalId: principalId
    principalType: principalType
  }
}

output blobEndpoint string = storageAccount_1XR3Um8QY.properties.primaryEndpoints.blob
output queueEndpoint string = storageAccount_1XR3Um8QY.properties.primaryEndpoints.queue
output tableEndpoint string = storageAccount_1XR3Um8QY.properties.primaryEndpoints.table
