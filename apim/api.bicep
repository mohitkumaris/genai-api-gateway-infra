// =============================================================================
// GenAI Orchestrator API Definition
// =============================================================================
// Defines the API and single operation: POST /orchestrate
// Backend is treated as a black box - no business logic here.
// =============================================================================

@description('Name of the parent APIM instance')
param apimName string

@description('Backend URL for the orchestrator service')
param backendUrl string

@description('API version identifier')
param apiVersion string = 'v1'

@description('API display name')
param apiDisplayName string = 'GenAI Orchestrator API'

// =============================================================================
// Reference existing APIM instance
// =============================================================================
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

// =============================================================================
// Backend Definition
// =============================================================================
resource backend 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apim
  name: 'genai-orchestrator-backend'
  properties: {
    protocol: 'http'
    url: backendUrl
    description: 'GenAI Orchestrator Service Backend'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

// =============================================================================
// API Definition
// =============================================================================
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'genai-orchestrator-api'
  properties: {
    displayName: apiDisplayName
    description: 'GenAI Platform Orchestration API - Single entry point for all GenAI operations'
    path: 'genai'
    apiVersion: apiVersion
    apiVersionSetId: apiVersionSet.id
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    serviceUrl: backendUrl
  }
}

// =============================================================================
// API Version Set
// =============================================================================
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apim
  name: 'genai-orchestrator-version-set'
  properties: {
    displayName: 'GenAI Orchestrator API Versions'
    versioningScheme: 'Segment'
  }
}

// =============================================================================
// Operation: POST /orchestrate
// =============================================================================
resource orchestrateOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: api
  name: 'post-orchestrate'
  properties: {
    displayName: 'Orchestrate GenAI Request'
    description: 'Submit a request to the GenAI orchestration engine'
    method: 'POST'
    urlTemplate: '/orchestrate'
    request: {
      description: 'Orchestration request payload'
      headers: [
        {
          name: 'Content-Type'
          type: 'string'
          required: true
          values: ['application/json']
        }
        {
          name: 'X-Request-Id'
          type: 'string'
          required: false
          description: 'Client-provided request correlation ID'
        }
      ]
      representations: [
        {
          contentType: 'application/json'
          schemaId: 'orchestrate-request-schema'
          typeName: 'OrchestrationRequest'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Successful orchestration response'
        representations: [
          {
            contentType: 'application/json'
            schemaId: 'orchestrate-response-schema'
            typeName: 'OrchestrationResponse'
          }
        ]
      }
      {
        statusCode: 400
        description: 'Bad request - invalid input'
      }
      {
        statusCode: 401
        description: 'Unauthorized - invalid or missing subscription key'
      }
      {
        statusCode: 429
        description: 'Too many requests - rate limit exceeded'
      }
      {
        statusCode: 500
        description: 'Internal server error'
      }
    ]
  }
}

// =============================================================================
// Request Schema
// =============================================================================
resource requestSchema 'Microsoft.ApiManagement/service/apis/schemas@2023-05-01-preview' = {
  parent: api
  name: 'orchestrate-request-schema'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {
      components: {
        schemas: {
          OrchestrationRequest: {
            type: 'object'
            required: ['prompt']
            properties: {
              prompt: {
                type: 'string'
                description: 'The user prompt to process'
              }
              context: {
                type: 'object'
                description: 'Additional context for the request'
              }
              options: {
                type: 'object'
                description: 'Processing options'
              }
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// Response Schema
// =============================================================================
resource responseSchema 'Microsoft.ApiManagement/service/apis/schemas@2023-05-01-preview' = {
  parent: api
  name: 'orchestrate-response-schema'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {
      components: {
        schemas: {
          OrchestrationResponse: {
            type: 'object'
            properties: {
              request_id: {
                type: 'string'
                description: 'Unique request identifier'
              }
              result: {
                type: 'object'
                description: 'The orchestration result'
              }
              metadata: {
                type: 'object'
                description: 'Response metadata'
              }
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// API Policy (references external XML)
// =============================================================================
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'xml'
    value: loadTextContent('../policies/inbound.xml')
  }
}

// =============================================================================
// Outputs
// =============================================================================
@description('The API ID')
output apiId string = api.id

@description('The API path')
output apiPath string = api.properties.path

@description('The backend ID')
output backendId string = backend.id
