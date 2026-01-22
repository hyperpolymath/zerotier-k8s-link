# Basic ZeroTier K8s Deployment Example

This guide shows how to deploy ZeroTier to a Kubernetes cluster for encrypted overlay networking.

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- ZeroTier Central account
- Network created in ZeroTier Central

## Step 1: Get Network Credentials

1. Log into https://my.zerotier.com
2. Create a network (or use existing)
3. Note the Network ID (16 characters)
4. Generate an API token: Account → API Access Tokens

## Step 2: Configure Environment

```bash
export ZEROTIER_NETWORK_ID="a0cbf4b62a123456"
export ZEROTIER_API_TOKEN="your-api-token-here"
```

## Step 3: Deploy to Cluster

```bash
# Deploy all components
just deploy

# Or manually:
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/daemonset.yaml
kubectl apply -f manifests/networkpolicy.yaml
```

## Step 4: Authorize Nodes

Option A: Use API (recommended):
```bash
just authorize-nodes
```

Option B: Manual authorization in ZeroTier Central:
1. Go to your network page
2. Scroll to "Members" section
3. Check the boxes next to your K8s nodes
4. Save

## Step 5: Verify Connectivity

```bash
# Check deployment status
just status

# View logs
just logs

# Check mesh health
just health-check a0cbf4b62a123456

# View mesh status from pods
just mesh-status
```

## Expected Output

```
$ just mesh-status
=== Mesh Status from K8s Nodes ===
200 listnetworks a0cbf4b62a123456 flatracoon-k8s-mesh 10.147.17.1/24 OK PRIVATE ztmesh123
200 listpeers <ztaddr> <path> <latency> <version> <role>
```

## Troubleshooting

### Nodes not joining
- Check pod logs: `kubectl -n zerotier-system logs daemonset/zerotier`
- Verify credentials in secret
- Ensure network exists in ZeroTier Central

### Nodes joined but not authorized
- Run `just authorize-nodes`
- Or manually authorize in ZeroTier Central web UI

### Cannot reach other nodes
- Check firewall rules allow UDP 9993
- Verify nodes show "OK" status in `zerotier-cli listnetworks`
- Check routing configuration

## Integration with IPFS

To bind IPFS to the ZeroTier interface:

```bash
# Get ZeroTier interface name
ZT_IFACE=$(zerotier-cli listnetworks | awk '{print $8}' | tail -1)

# Configure IPFS
ipfs config Addresses.Swarm --json '["/'${ZT_IFACE}'/tcp/4001"]'
```
