#!/usr/bin/env bash
# Botao de emergencia: instala Argo CD, ingress-nginx e o operator do CNPG.
# Fixe as versoes no ensaio e atualize as 3 variaveis abaixo.
set -euo pipefail

ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml"
CNPG_MANIFEST="https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.25.1/cnpg-1.25.1.yaml"

echo ">> Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts -f "$ARGOCD_MANIFEST"
kubectl -n argocd wait --for=condition=available deployment --all --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo ">> ingress-nginx"
kubectl apply -f "$INGRESS_MANIFEST"
kubectl wait -n ingress-nginx --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller --timeout=180s

echo ">> CloudNativePG operator"
kubectl apply --server-side -f "$CNPG_MANIFEST"
kubectl -n cnpg-system rollout status deployment/cnpg-controller-manager --timeout=180s

echo ">> OK"
