targetScope = 'resourceGroup'

@description('')
param location string = resourceGroup().location

@description('')
param principalId string

@description('')
param principalType string


resource cognitiveServicesAccount_PdkW2EYiQ 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: toLower(take('aoai${uniqueString(resourceGroup().id)}', 24))
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: toLower(take(concat('aoai', uniqueString(resourceGroup().id)), 24))
    publicNetworkAccess: 'Enabled'
  }
}

resource roleAssignment_jyEu31ZQ5 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: cognitiveServicesAccount_PdkW2EYiQ
  name: guid(cognitiveServicesAccount_PdkW2EYiQ.id, principalId, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442'))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
    principalId: principalId
    principalType: principalType
  }
}

resource cognitiveServicesAccountDeployment_O7cwEVxeg 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveServicesAccount_PdkW2EYiQ
  name: 'completions'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '1106'
    }
  }
}

resource cognitiveServicesAccountDeployment_llMkE7EWl 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: cognitiveServicesAccount_PdkW2EYiQ
  name: 'embeddings'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
  }
}

output connectionString string = 'Endpoint=${cognitiveServicesAccount_PdkW2EYiQ.properties.endpoint}'
