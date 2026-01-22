# ZeroTier K8s Link Examples

Example configurations and deployment guides for ZeroTier overlay networking in Kubernetes.

## Available Examples

### [basic-deployment.md](./basic-deployment.md)
Complete walkthrough of deploying ZeroTier to a Kubernetes cluster, including:
- Prerequisites and setup
- Credential configuration
- Deployment process
- Node authorization
- Health checking
- Troubleshooting tips

## Quick Start

```bash
# 1. Set credentials
export ZEROTIER_NETWORK_ID="your-network-id"
export ZEROTIER_API_TOKEN="your-api-token"

# 2. Deploy
just deploy

# 3. Authorize nodes
just authorize-nodes

# 4. Verify
just mesh-status
```

## Use Cases

- **Multi-cloud K8s clusters**: Connect nodes across AWS, GCP, Azure, on-prem
- **IPFS overlay**: Private IPFS network over ZeroTier mesh
- **Secure microservices**: End-to-end encrypted service communication
- **Development environments**: Secure access to remote K8s clusters

## Related Projects

- [flatracoon-netstack](https://github.com/hyperpolymath/flatracoon-netstack) - Complete network stack
- [twingate-helm-deploy](https://github.com/hyperpolymath/twingate-helm-deploy) - External access layer
- [ipfs-overlay](https://github.com/hyperpolymath/ipfs-overlay) - IPFS integration
