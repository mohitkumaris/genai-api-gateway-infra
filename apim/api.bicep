@description('Name of the parent APIM instance')
param apimName string

@description('Backend URL for the orchestrator service')
param backendUrl string

@description('API display name')
param apiDisplayName string = 'GenAI Orchestrator API'

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'genai-orchestrator-api'
  properties: {
    displayName: apiDisplayName
    description: 'GenAI Platform Orchestration API'
    path: 'genai'
    protocols: ['https']
    serviceUrl: backendUrl
    subscriptionRequired: true
  }
}

resource orchestrateOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: api
  name: 'post-orchestrate'
  properties: {
    displayName: 'Orchestrate GenAI Request'
    method: 'POST'
    urlTemplate: '/orchestrate'
    description: 'Submit a request to the GenAI orchestration engine'
  }
}

output apiId string = api.id
