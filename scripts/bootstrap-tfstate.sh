#!/usr/bin/env bash
# Run this ONCE before the first `terragrunt run-all apply`.
# Creates the Azure Storage account that holds all Terraform remote state.
# The storage account is created in $SA_LOCATION (default: eastus) which may
# differ from the resource group location if the RG already exists elsewhere.
set -euo pipefail

RG="crewmeister-tfstate-rg"
SA="crewmeistertfstate"
CONTAINER="tfstate"
RG_LOCATION="${1:-germanywestcentral}"   # RG location — only used if RG doesn't exist
SA_LOCATION="${2:-germanywestcentral}"  # Storage account location — use an allowed region

echo ">>> Ensuring resource group: $RG"
if az group show --name "$RG" &>/dev/null; then
  echo "    (already exists — skipping)"
else
  az group create --name "$RG" --location "$RG_LOCATION" --output none
  echo "    Created in $RG_LOCATION"
fi

echo ">>> Creating storage account: $SA (location: $SA_LOCATION)"
az storage account create \
  --name "$SA" \
  --resource-group "$RG" \
  --location "$SA_LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --output none

echo ">>> Creating blob container: $CONTAINER"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA" \
  --auth-mode login \
  --output none

echo ""
echo "✓ Remote state backend ready."
echo "  Storage account : $SA  ($SA_LOCATION)"
echo "  Container       : $CONTAINER"
