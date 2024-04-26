using static Aspire.Hosting.Azure.AzureBicepResource;

var builder = DistributedApplication.CreateBuilder(args);

// Azure Search Resource - with index
var cogsearch = builder.AddAzureSearch("cogsearch");

// Azure OpenAI Resource
var aoai = builder.AddAzureOpenAI("aoai")
    .AddDeployment(new AzureOpenAIDeployment("completions", "gpt-35-turbo", "1106"))
    .AddDeployment(new AzureOpenAIDeployment("embeddings", "text-embedding-ada-002", "2"));

// Azure CosmosDB Resource
// need to add containers for the database
//var cosmosdb = builder.AddAzureCosmosDB("cosmosdb")
//    .AddDatabase("vsai-database");

var cosmosdb = builder.AddBicepTemplate(
    name: "cosmosdb",
    bicepFile: "./bicep/cosmosdb.bicep")
    .WithParameter("keyVaultName","mykv");

var cosmosdbcnstring = cosmosdb.GetOutput("connectionString");

// Azure Storage Resource
var storage = builder.AddAzureStorage("storageold");

// Add blob containers for the storage account
// need to seed the blob containers with data
//var durablePromptBlobs = storage.AddBlobs("system-prompt");
//var configBlobs = storage.AddBlobs("memory-source");
//var productPolicy = storage.AddBlobs("product-policy");

var storage2 = builder.AddBicepTemplate(
    name: "storage",
    bicepFile: "./bicep/storage.bicep")
    .WithParameter(KnownParameters.PrincipalId)
    .WithParameter(KnownParameters.PrincipalType);

var storagecnstring = storage2.GetOutput("blobEndpoint");

// Azure Application Insights
//var appInsights = builder.AddAzureApplicationInsights("appinsights");

// Chat Service Web API
var chatapi = builder.AddProject<Projects.ChatServiceWebApi>("chatserviceapi")
    .WithEnvironment("ConnectionStrings__cosmosdb", cosmosdbcnstring)
    .WithEnvironment("ConnectionStrings__storage", storagecnstring)
    .WithReference(aoai)
    .WithReference(cogsearch);

// Search Frontend App
var frontend = builder.AddProject<Projects.Search>("search")
    .WithExternalHttpEndpoints()
    .WithReference(chatapi);

builder.Build().Run();
