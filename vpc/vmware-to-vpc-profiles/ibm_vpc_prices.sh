#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-eu-de}"           # e.g., eu-de, eu-gb, us-south, us-east, jp-tok, au-syd, ...
PROFILE_FILTER="${2:-}"        # optional, e.g., bx2-2x8 (substring match)

# 1) Find the Global Catalog service entry for "Virtual Server for VPC"
SERVICE_ID=$(
  curl -s "https://globalcatalog.cloud.ibm.com/api/v1?q=kind:service%20AND%20(name:%22is.instance%22%20OR%20label:%22Virtual%20Server%20for%20VPC%22)&_limit=50" \
  | jq -r '
      ( .resources // . )                             # GC can return {resources:[...]} or top-level array depending on query
      | (.[0].id // .[0]._id)                         # service id
    '
)

if [[ -z "${SERVICE_ID}" || "${SERVICE_ID}" == "null" ]]; then
  echo "Could not locate Global Catalog service id for Virtual Server for VPC (is.instance)"; exit 1
fi

# 2) List plans under the service; pick the pay-as-you-go/paid plan (usually 1 plan for VPC compute)
PLAN_ID=$(
  curl -s "https://globalcatalog.cloud.ibm.com/api/v1/${SERVICE_ID}/plan?_offset=0&_limit=50" \
  | jq -r '
      .resources
      | map(select(.metadata.pricing.type | ascii_downcase == "paid" or .metadata.type == "paid"))
      | (.[0].id // .[0]._id)
    '
)

if [[ -z "${PLAN_ID}" || "${PLAN_ID}" == "null" ]]; then
  echo "Could not find a paid plan under service ${SERVICE_ID}"; exit 1
fi

# 3) Find deployments to know the exact deployment_id for the region
DEPLOYMENT_ID=$(
  curl -s "https://globalcatalog.cloud.ibm.com/api/v1/${PLAN_ID}/pricing/deployment" \
  | jq -r --arg REGION "$REGION" '
      .resources
      | map(select(.deployment_region == $REGION or .deployment_location == $REGION))
      | (.[0].deployment_id // empty)
    '
)

if [[ -z "${DEPLOYMENT_ID}" ]]; then
  echo "Region ${REGION} not found in plan deployments. Try another region code."; exit 1
fi

# 4) Pull pricing for that deployment+region. This returns *all* VPC VS pricing metrics.
PRICING_JSON=$(
  curl -s "https://globalcatalog.cloud.ibm.com/api/v1/${DEPLOYMENT_ID}:global/pricing?deployment_region=${REGION}"
)

# 5) Render a clean table of hourly prices; filter by profile name if provided
echo "Region: ${REGION}"
echo "Deployment: ${DEPLOYMENT_ID}"
echo
echo "Profile, Metric, Currency, HourlyPrice"
echo "${PRICING_JSON}" | jq -r --arg PF "$PROFILE_FILTER" '
  # Accept either an array or an object root
  (if type=="array" then .[] else . end)
  # Accept either .resources (object/array) or the value itself
  | ( .resources // . )
  # If that’s an array, iterate; if it’s an object, pass through
  | (if type=="array" then .[] else . end)
  # Metrics may be missing; guard with ? and default to empty
  | (.metrics // [])[]
  | . as $m
  | ($m.metric_id // "") as $metric
  | ($m.resource_display_name // $metric) as $name
  | select(($PF|length==0) or ($name|test($PF;"i")) or ($metric|test($PF;"i")))
  | (.amounts // [])[]
  | .currency as $cur
  | (.prices // [])[]
  | select(.quantity_tier==1)
  | [$name, $metric, $cur, (.price|tostring)]
  | @csv
'

