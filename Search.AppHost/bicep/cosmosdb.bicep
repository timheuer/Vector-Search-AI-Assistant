targetScope = 'resourceGroup'

@description('')
param location string = resourceGroup().location

@description('')
param keyVaultName string

param containers array = [
  {
	name: 'embedding'
	partitionKeyPath: '/id'
  }
  {
	name: 'completions'
	partitionKeyPath: '/sessionId'
  }
  {
	name: 'product'
	partitionKeyPath: '/categoryId'
  }
  {
	name: 'customer'
	partitionKeyPath: '/customerId'
  }
  {
	name: 'leases'
	partitionKeyPath: '/id'
  }
]

resource keyVault_IeF8jZvXV 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource cosmosDBAccount_HFk1xSHh7 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: toLower(take('cosmosdb${uniqueString(resourceGroup().id)}', 24))
  location: location
  tags: {
    'aspire-resource-name': 'cosmosdb'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

resource cosmosDBSqlDatabase_CJ7aRtNeZ 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosDBAccount_HFk1xSHh7
  name: 'vsai-database'
  location: location
  properties: {
    resource: {
      id: 'vsai-database'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = [
  for container in containers: {
    parent: cosmosDBSqlDatabase_CJ7aRtNeZ
    name: container.name
    properties: {
      resource: {
        id: container.name
        partitionKey: {
          paths: [
            container.partitionKeyPath
          ]
          kind: 'Hash'
          version: 2
        }
      }
    }
  }
]

resource keyVaultSecret_Ddsc3HjrA 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault_IeF8jZvXV
  name: 'cosmos-key'
  location: location
  properties: {
    value: 'AccountEndpoint=${cosmosDBAccount_HFk1xSHh7.properties.documentEndpoint};AccountKey=${cosmosDBAccount_HFk1xSHh7.listkeys(cosmosDBAccount_HFk1xSHh7.apiVersion).primaryMasterKey}'
  }
}

output connectionString string = 'AccountEndpoint=${cosmosDBAccount_HFk1xSHh7.properties.documentEndpoint};AccountKey=${cosmosDBAccount_HFk1xSHh7.listkeys(cosmosDBAccount_HFk1xSHh7.apiVersion).primaryMasterKey}'