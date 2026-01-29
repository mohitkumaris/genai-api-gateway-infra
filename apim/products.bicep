// =============================================================================
// APIM Products and Subscriptions
// =============================================================================
// Defines tiered products: Free, Standard, Enterprise
// Each tier has configurable rate limits and quotas.
// =============================================================================

@description('Name of the parent APIM instance')
param apimName string

@description('Name of the API to associate with products')
param apiName string = 'genai-orchestrator-api'

// =============================================================================
// Reference existing APIM instance
// =============================================================================
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

// =============================================================================
// Reference existing API
// =============================================================================
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' existing = {
  parent: apim
  name: apiName
}

// =============================================================================
// Product: Free Tier
// =============================================================================
resource freeTierProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apim
  name: 'genai-free-tier'
  properties: {
    displayName: 'GenAI Free Tier'
    description: 'Free tier for evaluation and development. Limited to 100 calls/minute, 1000 calls/day.'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 10
    terms: 'Free tier is for evaluation purposes only. Rate limits apply.'
  }
}

resource freeTierApiLink 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: freeTierProduct
  name: apiName
}

resource freeTierPolicy 'Microsoft.ApiManagement/service/products/policies@2023-05-01-preview' = {
  parent: freeTierProduct
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
  <inbound>
    <rate-limit calls="100" renewal-period="60" />
    <quota calls="1000" renewal-period="86400" />
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}

// =============================================================================
// Product: Standard Tier
// =============================================================================
resource standardTierProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apim
  name: 'genai-standard-tier'
  properties: {
    displayName: 'GenAI Standard Tier'
    description: 'Standard tier for production workloads. 500 calls/minute, 10000 calls/day.'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 100
    terms: 'Standard tier for production usage. SLA applies.'
  }
}

resource standardTierApiLink 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: standardTierProduct
  name: apiName
}

resource standardTierPolicy 'Microsoft.ApiManagement/service/products/policies@2023-05-01-preview' = {
  parent: standardTierProduct
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
  <inbound>
    <rate-limit calls="500" renewal-period="60" />
    <quota calls="10000" renewal-period="86400" />
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}

// =============================================================================
// Product: Enterprise Tier
// =============================================================================
resource enterpriseTierProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apim
  name: 'genai-enterprise-tier'
  properties: {
    displayName: 'GenAI Enterprise Tier'
    description: 'Enterprise tier for high-volume workloads. 2000 calls/minute, unlimited daily quota.'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: true
    subscriptionsLimit: 1000
    terms: 'Enterprise tier with premium SLA and support.'
  }
}

resource enterpriseTierApiLink 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: enterpriseTierProduct
  name: apiName
}

resource enterpriseTierPolicy 'Microsoft.ApiManagement/service/products/policies@2023-05-01-preview' = {
  parent: enterpriseTierProduct
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
  <inbound>
    <rate-limit calls="2000" renewal-period="60" />
    <!-- No quota limit for enterprise tier -->
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}

// =============================================================================
// Groups for Product Access Control
// =============================================================================
resource developersGroup 'Microsoft.ApiManagement/service/groups@2023-05-01-preview' = {
  parent: apim
  name: 'genai-developers'
  properties: {
    displayName: 'GenAI Developers'
    description: 'Developers with access to GenAI APIs'
    type: 'custom'
  }
}

resource freeTierDevelopersAccess 'Microsoft.ApiManagement/service/products/groups@2023-05-01-preview' = {
  parent: freeTierProduct
  name: 'developers'
}

resource standardTierDevelopersAccess 'Microsoft.ApiManagement/service/products/groups@2023-05-01-preview' = {
  parent: standardTierProduct
  name: 'developers'
}

// =============================================================================
// Outputs
// =============================================================================
@description('Free tier product ID')
output freeTierProductId string = freeTierProduct.id

@description('Standard tier product ID')
output standardTierProductId string = standardTierProduct.id

@description('Enterprise tier product ID')
output enterpriseTierProductId string = enterpriseTierProduct.id
