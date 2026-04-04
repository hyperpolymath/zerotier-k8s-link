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


# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for zerotier-k8s-link..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '$HOME\|$ECLIPSE_DIR' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' . 2>/dev/null | head -5 || echo "  [OK] No hardcoded paths"
    @echo "Diagnostics complete."

# Guided tour of key features
tour:
    @echo "=== zerotier-k8s-link Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== zerotier-k8s-link Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/hyperpolymath/zerotier-k8s-link/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."

# Attempt to automatically install missing tools
heal:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Zerotier K8S Link Heal — Automatic Tool Installation"
    echo "═══════════════════════════════════════════════════"
    echo ""
if ! command -v just >/dev/null 2>&1; then
    echo "Installing just..."
    cargo install just 2>/dev/null || echo "Install just from https://just.systems"
fi
    echo ""
    echo "Heal complete. Run 'just doctor' to verify."


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"
