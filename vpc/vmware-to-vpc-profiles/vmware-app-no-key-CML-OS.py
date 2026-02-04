#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, render_template_string
import pandas as pd
import os
import logging
import re
from werkzeug.utils import secure_filename
from collections import defaultdict
import math

# IBM Cloud VPC SDK
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator

# ------------------------------------------------------------------------------
# Flask setup
# ------------------------------------------------------------------------------
app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# ------------------------------------------------------------------------------
# IBM Cloud VPC Setup
# ------------------------------------------------------------------------------
SERVICE_URL = os.environ.get('IBM_VPC_URL', 'https://us-south.iaas.cloud.ibm.com/v1')
API_KEY = os.environ.get('IBM_CLOUD_API_KEY')
if not API_KEY:
    try:
        import getpass
        API_KEY = getpass.getpass('Enter IBM Cloud API key: ')
    except Exception:
        API_KEY = input('Enter IBM Cloud API key: ')

authenticator = IAMAuthenticator(API_KEY)
vpc_service = VpcV1(version='2025-04-29', authenticator=authenticator)
vpc_service.set_service_url(SERVICE_URL)

# ------------------------------------------------------------------------------
# HTML templates (inline)
# ------------------------------------------------------------------------------
PAGE_TMPL = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Converter for VMware Servers List to IBM Cloud VPC VSI</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 24px; }
    h1 { margin-bottom: 8px; }
    .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin-bottom: 24px; box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
    .summary, .data, .images, .unmatched { border-collapse: collapse; width: 100%; font-size: 14px; }
    table { margin-top: 8px; }
    th, td { border: 1px solid #e5e7eb; padding: 8px; vertical-align: top; }
    th { background: #f9fafb; text-align: left; }
    .hint { color: #6b7280; font-size: 13px; }
    .ok { color: #047857; }
    .warn { color: #b45309; }
    .bad { color: #b91c1c; }
    .grid { display: grid; grid-template-columns: 1fr; gap: 24px; }
    @media (min-width: 1100px) { .grid { grid-template-columns: 1fr; } }
    .upload { display: inline-grid; gap: 8px; }
    .btn { background: #111827; color: #fff; border: 0; padding: 10px 14px; border-radius: 8px; cursor: pointer; }
    .btn:hover { background: #0b1220; }
    input[type=file] { padding: 6px; border: 1px solid #e5e7eb; border-radius: 8px; }
    code { background: #f3f4f6; padding: 2px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <h1>Converter for VMware Servers List to IBM Cloud VPC VSI</h1>
  <p class="hint">Upload your Excel (sheet <code>vInfo</code>). We read CPUs (col L), Memory (col M) and OS (col I).</p>
  <div class="card">
    <form class="upload" method="POST" enctype="multipart/form-data">
      <input type="file" name="file" accept=".xlsx,.xls" required />
      <button class="btn" type="submit">Process Excel</button>
    </form>
  </div>

  {% if error %}
    <div class="card">
      <h3 class="bad">Error</h3>
      <pre>{{ error }}</pre>
    </div>
  {% endif %}

  {% if summary_table %}
  <div class="grid">
    <div class="card">
      <h3>Profile Cost Summary</h3>
      <p class="hint">Totals use profile pricing from the VPC API (when provided).</p>
      {{ summary_table | safe }}
    </div>

    <div class="card">
      <h3>OS Image Coverage</h3>
      <p class="hint">How many VMs mapped to each public image (family/version).</p>
      {{ image_table | safe }}
    </div>

    {% if unmatched_table %}
    <div class="card">
      <h3>Unmatched / Unsupported OS</h3>
      <p class="hint">Rows whose OS had no suitable public image, or were 32-bit.</p>
      {{ unmatched_table | safe }}
    </div>
    {% endif %}

    <div class="card">
      <h3>Full Processed Data</h3>
      <p class="hint">Includes CPUs, memory, selected VPC profile, price (if available), and mapped image (name + id + note).</p>
      {{ data_table | safe }}
    </div>
  </div>
  {% endif %}
</body>
</html>
"""

# ------------------------------------------------------------------------------
# ONE-TO-ONE OS → TARGET FAMILY/MAJOR MAPPING (exact label match)
# Each entry maps a VMware OS label (as in Excel col I) to a target:
#   {'family': <vpc_family>, 'major': <int>, 'note': '...'}
# For unsupported 32-bit, use {'unsupported': True, 'note': 'unsupported: 32-bit OS'}
# ------------------------------------------------------------------------------
OS_TO_TARGET = {
    "CentOS 4/5 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS→CentOS 7"},
    "CentOS 4/5/6 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS→CentOS 7"},
    "CentOS 4/5/6/7 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS 7"},
    "CentOS 6 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS→CentOS 7"},
    "CentOS 7 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS 7"},
    "CentOS 7 (64-bit)": {"family": "centos", "major": 7, "note": "mapped: CentOS→CentOS 7"},
    "Debian GNU/Linux 6 (64-bit)": {"family": "debian", "major": 12, "note": "mapped: Debian 12"},
    "Microsoft Windows 10 (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows 10 (64-bit)": {"family": "windows", "major": 2022, "note": "mapped: client→Windows 2022"},
    "Microsoft Windows 11 (64-bit)": {"family": "windows", "major": 2022, "note": "mapped: client→Windows 2022"},
    "Microsoft Windows 7 (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows NT": {"unsupported": True, "note": "unsupported: legacy OS"},
    "Microsoft Windows Server 2003 (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows Server 2003 Standard (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows Server 2003 Standard (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2003→2019"},
    "Microsoft Windows Server 2003 Web Edition (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows Server 2008 (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Microsoft Windows Server 2008 (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2008→2019"},
    "Microsoft Windows Server 2008 R2 (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2008 R2→2019"},
    "Microsoft Windows Server 2012 (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2012→2019"},
    "Microsoft Windows Server 2012 R2 (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2012 R2→2019"},
    "Microsoft Windows Server 2016 (64-bit)": {"family": "windows", "major": 2016, "note": "mapped: 2016"},
    "Microsoft Windows Server 2019 (64-bit)": {"family": "windows", "major": 2019, "note": "mapped: 2019"},
    "Microsoft Windows Server 2022 (64-bit)": {"family": "windows", "major": 2022, "note": "mapped: 2022"},
    "Microsoft Windows Server 2025 (64-bit)": {"family": "windows", "major": 2022, "note": "mapped: 2025→2022"},
    "Microsoft Windows XP Professional (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Oracle Linux 4/5 (64-bit)": {"family": "redhat", "major": 9, "note": "mapped: Oracle→RHEL 9"},
    "Oracle Linux 4/5/6 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: Oracle→RHEL 9"},
    "Oracle Linux 6 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: Oracle→redhat 9"},
    "Oracle Linux 7 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: Oracle→redhat 9"},
    "Oracle Linux 8 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: Oracle→redhat 9"},
    "Oracle Linux 9 (64-bit)": {"family": "redhat", "major": 9, "note": "mapped: Oracle→Rocky 9"},
    "Other (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Other 2.6.x Linux (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Other 2.6.x Linux (64-bit)": {"family": "ubuntu", "major": 22, "note": "mapped: generic→Ubuntu 22.04 LTS"},
    "Other Linux (64-bit)": {"family": "ubuntu", "major": 22, "note": "mapped: generic→Ubuntu 22.04 LTS"},
    "Red Hat Enterprise Linux 4 (32-bit)": {"unsupported": True, "note": "unsupported: 32-bit OS"},
    "Red Hat Enterprise Linux 5 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: RHEL 5→RHEL 8"},
    "Red Hat Enterprise Linux 6 (64-bit)": {"family": "redhat", "major": 8, "note": "mapped: RHEL 6→RHEL 8"},
    "Rocky Linux (64-bit)": {"family": "rocky", "major": 9, "note": "mapped: Rocky 9"},
    "SUSE Linux Enterprise 12 (64-bit)": {"family": "sles", "major": 12, "note": "mapped: SLES 12"},
    "Ubuntu Linux (64-bit)": {"family": "ubuntu", "major": 22, "note": "mapped: Ubuntu 22.04 LTS"},
}

# ------------------------------------------------------------------------------
# Helpers: instance profiles and prices
# ------------------------------------------------------------------------------
def get_vpc_profiles():
    """
    Return list of tuples (cpus, memory_gb, name) for available instance profiles,
    sorted ascending, excluding the 'bz2' family.
    """
    profiles_list = []
    try:
        response = vpc_service.list_instance_profiles()
        result = response.get_result() or {}
        for profile in result.get('profiles', []):
            name = profile.get('name', '')
            m = re.search(r'-(\d+)x(\d+)', name)
            if m:
                cpus = int(m.group(1))
                mem = int(m.group(2))
                if 'bz2' in name.lower():
                    continue
                profiles_list.append((cpus, mem, name))
    except Exception as e:
        logging.error(f"Error fetching instance profiles: {e}")

    profiles_list.sort()
    logging.info(f"Profiles retrieved (excl. bz2): {len(profiles_list)}")
    return profiles_list


def get_vpc_prices():
    """
    Attempt to get per-profile price from the profiles endpoint if present.
    Returns { profile_name: price_float }.
    Note: Pricing may not be returned by the API in all accounts/regions.
    """
    price_dict = {}
    try:
        response = vpc_service.list_instance_profiles()
        result = response.get_result() or {}
        for profile in result.get('profiles', []):
            name = profile.get('name', '')
            price = None
            if isinstance(profile.get('price'), dict):
                v = profile['price'].get('value')
                if v is not None:
                    try:
                        price = float(v)
                    except:
                        price = None
            if price is not None and 'bz2' not in name.lower():
                price_dict[name] = price
    except Exception as e:
        logging.warning(f"Pricing not available from API: {e}")
    logging.info(f"Pricing entries found: {len(price_dict)}")
    return price_dict

# ------------------------------------------------------------------------------
# Memory rounding & profile matching
# ------------------------------------------------------------------------------
def round_memory(mem):
    """
    VMware memory (MB?) → rounded VPC profile GB steps (as per original logic).
    Adjust if your input is already in GB.
    """
    thresholds = [128, 1024, 2048, 4096, 6136, 8192, 12288, 16384, 24576, 32768]
    rounded_values = [0, 1, 2, 4, 6, 8, 12, 16, 24, 32]
    try:
        val = float(mem)
    except:
        val = 0.0
    for i, t in enumerate(thresholds):
        if val <= t:
            return rounded_values[i]
    return 32

def find_best_match(cpus, mem_rounded, profiles_list):
    """
    First profile with CPUs >= requested and Memory >= requested (both rounded).
    """
    for pcpu, pmem, pname in profiles_list:
        if pcpu >= cpus and pmem >= mem_rounded:
            return pname
    return "Unknown"

# ------------------------------------------------------------------------------
# Image discovery
# ------------------------------------------------------------------------------
def get_vpc_images():
    """
    Index public, available images by normalized family and major version:
      images_idx[family][major] -> [image_rec, ...]
    image_rec = { id, name, os_name, os_family, os_version, arch, major }
    """
    images_idx = defaultdict(lambda: defaultdict(list))
    images_all = []

    try:
        resp = vpc_service.list_images(limit=100)
        while True:
            result = resp.get_result() or {}
            for img in result.get('images', []):
                if img.get('visibility') != 'public' or img.get('status') != 'available':
                    continue
                os_info = img.get('operating_system') or {}
                os_family = (os_info.get('family') or '').lower().strip()
                os_name   = (os_info.get('name') or '').lower().strip()
                os_ver    = (os_info.get('version') or '').lower().strip()
                arch      = (os_info.get('architecture') or '').lower().strip()

                # Derive "major" version (year for Windows; first number for Linux)
                major = None
                m = re.search(r'(\d{4})', os_ver)  # windows years
                if not m:
                    m = re.search(r'(\d+)', os_ver or os_name)
                if m:
                    try:
                        major = int(m.group(1))
                    except:
                        major = None

                rec = {
                    'id': img.get('id'),
                    'name': img.get('name'),
                    'os_name': os_name,
                    'os_family': os_family,
                    'os_version': os_ver,
                    'arch': arch,
                    'major': major
                }
                images_all.append(rec)
                if os_family and major is not None:
                    images_idx[os_family][major].append(rec)

            # pagination
            if result.get('next') and result['next'].get('start'):
                resp = vpc_service.list_images(limit=100, start=result['next']['start'])
            else:
                break
    except Exception as e:
        logging.error(f"Error fetching images: {e}")

    logging.info(f"Indexed images: total={len(images_all)}; families={list(images_idx.keys())}")
    return images_idx, images_all

# ------------------------------------------------------------------------------
# Mapping selection using the ONE-TO-ONE table
# ------------------------------------------------------------------------------
def _nearest_version_match(images_idx_family, target_major):
    """
    Find nearest major version available (bias upwards on ties).
    """
    if not images_idx_family:
        return None, None
    majors = sorted(images_idx_family.keys())
    if target_major is None:
        mv = majors[-1]
        return mv, images_idx_family[mv][0]
    best = None
    best_dist = math.inf
    for v in majors:
        d = abs(v - target_major)
        if d < best_dist or (d == best_dist and (best is None or v > best)):
            best = v
            best_dist = d
    return best, images_idx_family[best][0] if best is not None else (None, None)

def choose_image_for_target(target, images_idx):
    """
    Given a target {'family','major','note'} choose an image from images_idx.
    Returns (image_rec or None, match_note).
    """
    fam = (target.get('family') or '').lower().strip()
    major = target.get('major')
    base_note = target.get('note', 'mapped')

    fam_idx = images_idx.get(fam)
    if not fam_idx:
        return None, f"{base_note}; no images for family '{fam}' in region"

    # exact major first
    if major in fam_idx and fam_idx[major]:
        return fam_idx[major][0], f"{base_note}; mapped exact"
    # nearest major in same family
    nearest_v, img = _nearest_version_match(fam_idx, major)
    if img:
        return img, f"{base_note}; mapped nearest ({nearest_v})"
    return None, f"{base_note}; no image match in family"

def map_vmw_label_to_target(os_label):
    """
    Exact label mapping. If not found, return None to mark as unmapped.
    """
    key = (os_label or "").strip()
    return OS_TO_TARGET.get(key)

# ------------------------------------------------------------------------------
# Flask route
# ------------------------------------------------------------------------------
@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'GET':
        return render_template_string(PAGE_TMPL)

    # POST
    file = request.files.get('file')
    if not file:
        return render_template_string(PAGE_TMPL, error="No file uploaded.")

    try:
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        # Load Excel (sheet 'vInfo')
        df = pd.read_excel(filepath, sheet_name='vInfo', engine='openpyxl')

        # Extract columns:
        # OS name from Column I (index 8)
        df.loc[:, 'Requested OS'] = df.iloc[:, 8].astype(str).str.strip()

        # CPUs from Column L (index 11), Memory from Column M (index 12)
        df.loc[:, 'CPUs'] = pd.to_numeric(df.iloc[:, 11], errors='coerce').fillna(0).astype(int)
        df.loc[:, 'Memory'] = pd.to_numeric(df.iloc[:, 12], errors='coerce')  # keep numeric; may be MB or GB
        df.loc[:, 'Mem Rounded'] = df['Memory'].apply(round_memory).fillna(0).astype(int)

        # Fetch profiles and (if available) prices
        vpc_profiles = get_vpc_profiles()
        vpc_prices = get_vpc_prices()

        # Match instance profiles
        df.loc[:, 'Instance Profile'] = df.apply(
            lambda r: find_best_match(r['CPUs'], r['Mem Rounded'], vpc_profiles), axis=1
        )

        # Map prices
        df.loc[:, 'VPC Price ($)'] = df['Instance Profile'].map(vpc_prices)

        # Fetch images index once
        images_idx, _ = get_vpc_images()

        # Map OS → image using strict one-to-one dictionary
        def map_os_label(os_str):
            target = map_vmw_label_to_target(os_str)
            if not target:
                # Strict behavior: no mapping configured
                return pd.Series({
                    'Target Family': None,
                    'Target Major': None,
                    'Image Name': None,
                    'Image ID': None,
                    'Image Match Note': "no mapping configured for label"
                })

            if target.get('unsupported'):
                return pd.Series({
                    'Target Family': None,
                    'Target Major': None,
                    'Image Name': None,
                    'Image ID': None,
                    'Image Match Note': target.get('note', 'unsupported')
                })

            img, note = choose_image_for_target(target, images_idx)
            if img:
                return pd.Series({
                    'Target Family': target.get('family'),
                    'Target Major': target.get('major'),
                    'Image Name': img['name'],
                    'Image ID': img['id'],
                    'Image Match Note': note
                })
            else:
                return pd.Series({
                    'Target Family': target.get('family'),
                    'Target Major': target.get('major'),
                    'Image Name': None,
                    'Image ID': None,
                    'Image Match Note': note
                })

        mapped = df['Requested OS'].apply(map_os_label)
        df = pd.concat([df, mapped], axis=1)

        # Summaries
        summary_df = df.groupby('Instance Profile', dropna=False).agg(
            Number_Listed=('Instance Profile', 'count'),
            Total_Price=('VPC Price ($)', 'sum')
        ).reset_index()
        summary_df['Total_Price'] = summary_df['Total_Price'].apply(
            lambda x: f"${x:.2f}" if pd.notna(x) else "$0.00"
        )

        image_summary = df.groupby(
            ['Target Family', 'Target Major', 'Image Name'], dropna=False
        ).size().reset_index(name='Count').sort_values(['Target Family','Target Major','Image Name'])

        unmatched_df = df[df['Image ID'].isna()].groupby('Requested OS').size().reset_index(name='Count')
        unmatched_html = unmatched_df.to_html(classes='unmatched', index=False, escape=False) if len(unmatched_df) else None

        # Display tables (keep original columns visible + our computed ones)
        display_cols = []
        base_cols = list(df.columns[:8])  # keep initial metadata cols (0..7) if useful
        for c in base_cols:
            if c not in display_cols:
                display_cols.append(c)
        for c in ['Requested OS', 'CPUs', 'Memory', 'Mem Rounded',
                  'Instance Profile', 'VPC Price ($)',
                  'Target Family', 'Target Major', 'Image Name', 'Image ID', 'Image Match Note']:
            if c in df.columns and c not in display_cols:
                display_cols.append(c)

        data_table_html = df[display_cols].to_html(classes='data', index=False, escape=False)
        summary_html = summary_df.to_html(classes='summary', index=False, escape=False)
        image_html = image_summary.to_html(classes='images', index=False, escape=False)

        return render_template_string(
            PAGE_TMPL,
            summary_table=summary_html,
            data_table=data_table_html,
            image_table=image_html,
            unmatched_table=unmatched_html
        )

    except Exception as e:
        logging.exception("Processing error")
        return render_template_string(PAGE_TMPL, error=str(e))


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5001)),
            debug=True, use_reloader=False)
