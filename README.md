# GenAI API Gateway Infrastructure

> **Azure API Management infrastructure-as-code for the GenAI platform edge control plane.**

This repository defines **platform governance** for API exposure, authentication, rate limiting, quotas, and request forwarding. It contains **zero application logic**.

## 🎯 Purpose

| ✅ This Repo Does | ❌ This Repo Does NOT |
|-------------------|----------------------|
| API exposure via APIM | Contain application code |
| API key authentication | Contain business logic |
| Rate limiting & quotas | Call LLMs or agents |
| Request forwarding | Implement FastAPI |
| TLS enforcement | Define backend behavior |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Edge Control Plane                          │
│  ┌──────────┐    ┌─────────────────────────────────────────┐   │
│  │  Client  │───▶│         Azure API Management            │   │
│  └──────────┘    │  ┌─────────┐ ┌─────────┐ ┌───────────┐  │   │
│                  │  │  Auth   │ │  Rate   │ │  Quota    │  │   │
│       POST       │  │  (Key)  │ │  Limit  │ │  Enforce  │  │   │
│    /orchestrate  │  └─────────┘ └─────────┘ └───────────┘  │   │
│                  └─────────────────┬───────────────────────┘   │
│                                    │                            │
└────────────────────────────────────┼────────────────────────────┘
                                     │
                                     ▼
                    ┌────────────────────────────────┐
                    │   GenAI Orchestrator (Backend) │
                    │         [BLACK BOX]            │
                    └────────────────────────────────┘
```

## 📁 Repository Structure

```
genai-api-gateway-infra/
├── apim/
│   ├── apim.bicep              # API Management instance
│   ├── api.bicep               # API + backend definition
│   └── products.bicep          # Products / subscriptions
│
├── policies/
│   ├── inbound.xml             # Auth, rate limit, headers
│   ├── inbound.arm.json        # ARM-format policy for deployment
│   ├── outbound.xml            # Response pass-through
│   └── backend.xml             # Forwarding rules
│
├── parameters/
│   ├── dev.json                # Development environment
│   └── prod.json               # Production (gitignored - sensitive)
│
├── README.md
└── .gitignore
```

## 🔐 Security Model

| Layer | Control |
|-------|---------|
| **Authentication** | API Key (`Ocp-Apim-Subscription-Key`) required |
| **Authorization** | Product-based access (Free/Standard/Enterprise) |
| **Encryption** | TLS 1.2+ enforced at gateway |
| **Future** | Azure Entra ID upgrade path available |

## 🚦 Traffic Control

**Default Rate Limit:** 60 calls/minute per subscription (configured in `inbound.xml`)

| Product | Rate Limit | Daily Quota | Approval |
|---------|------------|-------------|----------|
| **Free** | 100/min | 1,000 | Auto |
| **Standard** | 500/min | 10,000 | Manual |
| **Enterprise** | 2,000/min | Unlimited | Manual |

## 🧠 Observability

- **Request ID**: Client-provided or auto-generated `X-Request-Id` forwarded to backend
- **APIM Trace**: `X-APIM-Request-Id` for gateway-level debugging
- **Processing Time**: `X-APIM-Processing-Time-Ms` header
- **Application Insights**: Full request/response logging (configurable)
- **Error Passthrough**: Backend errors preserved, not swallowed

## 🚀 Deployment

### Prerequisites

- Azure CLI with Bicep support
- Azure subscription with Contributor access
- Resource group created

### Validate Templates

```bash
# Validate Bicep syntax
az bicep build --file apim/apim.bicep
az bicep build --file apim/api.bicep
az bicep build --file apim/products.bicep
```

### Deploy to Development

```bash
# Create resource group
az group create --name rg-genai-apim-dev --location eastus

# Deploy APIM instance
az deployment group create \
  --resource-group rg-genai-apim-dev \
  --template-file apim/apim.bicep \
  --parameters @parameters/dev.json

# Deploy API definition
az deployment group create \
  --resource-group rg-genai-apim-dev \
  --template-file apim/api.bicep \
  --parameters apimName=genai-apim-dev \
               backendUrl=https://genai-orchestrator-dev.azurewebsites.net

# Deploy products
az deployment group create \
  --resource-group rg-genai-apim-dev \
  --template-file apim/products.bicep \
  --parameters apimName=genai-apim-dev
```

### Deploy to Production

```bash
# Create resource group
az group create --name rg-genai-apim-prod --location eastus

# Deploy with production parameters
az deployment group create \
  --resource-group rg-genai-apim-prod \
  --template-file apim/apim.bicep \
  --parameters @parameters/prod.json

# Deploy API and products (same pattern as dev)
```

## 📋 API Specification

### Endpoint

```
POST https://<apim-name>.azure-api.net/genai/orchestrate
```

### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Ocp-Apim-Subscription-Key` | ✅ | API subscription key |
| `Content-Type` | ✅ | Must be `application/json` |
| `X-Request-Id` | ❌ | Client correlation ID (auto-generated if missing) |

### Request Body

Request body is passed through to the backend as-is. The gateway does not enforce a specific schema.

### Response Headers

| Header | Description |
|--------|-------------|
| `X-Request-Id` | Request correlation ID |
| `X-APIM-Request-Id` | Gateway trace ID |
| `X-APIM-Processing-Time-Ms` | Gateway processing time |

## 🚨 Non-Negotiable Constraints

1. **IaC only** - Bicep/ARM templates, no imperative scripts
2. **Azure APIM** - No alternative gateways
3. **Single operation** - `POST /orchestrate` only
4. **Backend as black box** - No assumptions about orchestrator implementation
5. **No application logic** - Gateway policies only
6. **Preserve responses** - Never swallow or transform backend responses

## 📄 License

Internal use only. GenAI Platform team.
