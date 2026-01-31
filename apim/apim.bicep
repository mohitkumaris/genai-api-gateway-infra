// =============================================================================
// Azure API Management Instance
// =============================================================================
// This Bicep template deploys the core APIM instance for the GenAI platform.
// It provides: API exposure, authentication, rate limiting, and request forwarding.
// =============================================================================

@description('Name of the API Management instance')
param apimName string

@description('Location for the APIM instance')
param location string = resourceGroup().location

@description('SKU for the APIM instance')
@allowed([
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Developer'

@description('SKU capacity (number of deployed units)')
param skuCapacity int = 1

@description('Publisher email for APIM notifications')
param publisherEmail string

@description('Publisher organization name')
param publisherName string

@description('Backend orchestrator service URL')
param backendUrl string

@description('Application Insights resource ID for observability')
param appInsightsId string = ''

@description('Application Insights instrumentation key')
param appInsightsKey string = ''

@description('Tags for the resources')
param tags object = {}

// =============================================================================
// API Management Instance
// =============================================================================
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }

  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'false'
    }
  }
}

// =============================================================================
// Named Value: Backend URL
// =============================================================================
resource backendUrlNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apim
  name: 'backend-orchestrator-url'
  properties: {
    displayName: 'backend-orchestrator-url'
    value: backendUrl
    secret: false
  }
}

// =============================================================================
// Application Insights Logger (conditional)
// =============================================================================
resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(appInsightsId)) {
  parent: apim
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsKey
    }
  }
}

// =============================================================================
// Diagnostic Settings for API-level logging
// =============================================================================
resource apimDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2023-05-01-preview' = if (!empty(appInsightsId)) {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: appInsightsLogger.id
    alwaysLog: 'allErrors'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: ['X-Request-Id', 'X-Correlation-Id']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['X-Request-Id', 'X-APIM-Request-Id']
        body: {
          bytes: 1024
        }
      }
    }
    backend: {
      request: {
        headers: ['X-Request-Id']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: []
        body: {
          bytes: 1024
        }
      }
    }
  }
}

// =============================================================================
// Outputs
// =============================================================================
@description('The resource ID of the APIM instance')
output apimId string = apim.id

@description('The name of the APIM instance')
output apimName string = apim.name

@description('The gateway URL of the APIM instance')
output gatewayUrl string = apim.properties.gatewayUrl

