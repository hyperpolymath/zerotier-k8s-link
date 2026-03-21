# SPDX-License-Identifier: PMPL-1.0
# Justfile - ZeroTier K8s Link deployment automation

default:
    @just --list

# Show current deployment status
status:
    @echo "=== ZeroTier Deployment Status ==="
    @kubectl -n zerotier-system get all 2>/dev/null || echo "Not deployed yet"

# Deploy ZeroTier to Kubernetes cluster
deploy:
    @echo "Deploying ZeroTier to Kubernetes..."
    kubectl apply -f manifests/namespace.yaml
    kubectl apply -f manifests/secret.yaml
    kubectl apply -f manifests/configmap.yaml
    kubectl apply -f manifests/daemonset.yaml
    kubectl apply -f manifests/networkpolicy.yaml
    @echo "✓ Deployment complete"
    @just status

# Remove ZeroTier from cluster
undeploy:
    @echo "Removing ZeroTier deployment..."
    kubectl delete -f manifests/ --ignore-not-found=true
    @echo "✓ Cleanup complete"

# Configure secrets (requires ZEROTIER_NETWORK_ID and ZEROTIER_API_TOKEN env vars)
configure-secrets:
    #!/usr/bin/env bash
    if [ -z "$ZEROTIER_NETWORK_ID" ] || [ -z "$ZEROTIER_API_TOKEN" ]; then
        echo "Error: Set ZEROTIER_NETWORK_ID and ZEROTIER_API_TOKEN environment variables"
        exit 1
    fi
    kubectl create secret generic zerotier-credentials \
        -n zerotier-system \
        --from-literal=network-id="$ZEROTIER_NETWORK_ID" \
        --from-literal=api-token="$ZEROTIER_API_TOKEN" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Secrets configured"

# Authorize all pending nodes via ZeroTier API
authorize-nodes:
    @bash scripts/authorize-nodes.sh

# Check mesh health
health-check NETWORK_ID:
    @bash scripts/health-check.sh {{NETWORK_ID}}

# Get mesh status from all nodes
mesh-status:
    @echo "=== Mesh Status from K8s Nodes ==="
    @kubectl -n zerotier-system exec -it daemonset/zerotier -- zerotier-cli listnetworks || true
    @kubectl -n zerotier-system exec -it daemonset/zerotier -- zerotier-cli listpeers || true

# Watch pod logs
logs:
    kubectl -n zerotier-system logs -f daemonset/zerotier --all-containers=true

# Validate manifests
validate:
    @echo "Validating Kubernetes manifests..."
    @for file in manifests/*.yaml; do \
        echo "Checking $$file..."; \
        kubectl apply --dry-run=client -f $$file > /dev/null; \
    done
    @echo "✓ All manifests valid"

# Run lint checks
lint:
    @echo "Running lint checks..."
    @shellcheck scripts/*.sh
    @yamllint manifests/*.yaml

# Clean up resources
clean:
    @just undeploy

# Complete setup from scratch
setup: configure-secrets deploy authorize-nodes
    @echo "✓ Setup complete. Check status with: just status"


# [AUTO-GENERATED] Multi-arch / RISC-V target
build-riscv:
	@echo "Building for RISC-V..."
	cross build --target riscv64gc-unknown-linux-gnu

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"
