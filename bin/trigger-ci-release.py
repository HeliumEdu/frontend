#!/usr/bin/env python

import os
import sys

import boto3
import requests

ENVIRONMENT = os.environ.get("ENVIRONMENT")
FRONTEND_ROLLBAR_SERVER_ITEM_ACCESS_TOKEN = os.environ.get("FRONTEND_ROLLBAR_SERVER_ITEM_ACCESS_TOKEN")
VERSION = 'latest'
DEPLOY_SOURCE_MAPS = True
ENVIRONMENT_PREFIX = f'{ENVIRONMENT}.' if 'prod' not in ENVIRONMENT else ''
BASE_URL = f'https://www.{ENVIRONMENT_PREFIX}heliumedu.com'

if not ENVIRONMENT or not FRONTEND_ROLLBAR_SERVER_ITEM_ACCESS_TOKEN:
    print(
        "ERROR: Set all required env vars: ENVIRONMENT, FRONTEND_ROLLBAR_SERVER_ITEM_ACCESS_TOKEN.")
    sys.exit(1)

#####################################################################
# Release frontend code from artifact S3 bucket to live
#####################################################################

# TODO: migrate this deployment code in to `heliumcli`, then it can be removed from deploy and frontend

s3 = boto3.resource('s3')
source_bucket_name = "heliumedu"
source_bucket = s3.Bucket(source_bucket_name)
dest_bucket_name = f"heliumedu.{ENVIRONMENT}.frontend.static"
dest_bucket = s3.Bucket(dest_bucket_name)


def upload_source_map(minified_url, source_map_key):
    s3_client = boto3.client('s3')

    os.makedirs('source_maps', exist_ok=True)

    source_map_path = os.path.join('source_maps', os.path.basename(obj.key))
    s3_client.download_file(source_bucket_name, source_map_key, source_map_path)
    with open(source_map_path, 'rb') as f:
        data = {
            'access_token': FRONTEND_ROLLBAR_SERVER_ITEM_ACCESS_TOKEN,
            'version': VERSION,
            'minified_url': minified_url,
        }
        files = {
            'source_map': f
        }

        response = requests.post('https://api.rollbar.com/api/1/sourcemap', data=data, files=files)

        print(f"--> Response from {obj.key} source map upload: {response.content}")


# Copy assets first, so that new versioned bundles exist before pages are updated

assets_source_prefix = f"helium/frontend/{VERSION}/assets"
assets_dest_prefix = "assets/"
print(f"Copying frontend resources from {source_bucket_name}{assets_source_prefix} to {dest_bucket_name} ...")
for obj in source_bucket.objects.filter(Prefix=assets_source_prefix):
    new_key = f"{assets_dest_prefix}" + obj.key[len(assets_source_prefix):].lstrip("/")

    if (obj.key.endswith(".min.js.map") or obj.key.endswith(".min.css.map")) and not DEPLOY_SOURCE_MAPS:
        print(f"Skipping file {obj.key}, DEPLOY_SOURCE_MAPS={DEPLOY_SOURCE_MAPS}")
    else:
        copy_source = {
            'Bucket': source_bucket_name,
            'Key': obj.key
        }
        dest_bucket.Object(new_key).copy_from(CopySource=copy_source)
        print(f"--> '{obj.key}' to '{new_key}'")

    if obj.key.endswith(".min.js.map"):
        # try:
        new_key_url = f"{BASE_URL}/{new_key}"
        upload_source_map(new_key_url.removesuffix(".map"), obj.key)
        # except Exception as e:
        #     print(f"An error occurred uploading JS source map {new_key}: {e}")

source_prefix = f"helium/frontend/{VERSION}"
print(f"Copying frontend resources from {source_bucket_name}{source_prefix} to {dest_bucket_name} ...")
for obj in source_bucket.objects.filter(Prefix=source_prefix):
    # Skip assets, as we've already moved them in to place
    if obj.key.startswith(assets_source_prefix):
        continue

    new_key = obj.key[len(source_prefix):].lstrip("/")
    copy_source = {
        'Bucket': source_bucket_name,
        'Key': obj.key
    }
    dest_bucket.Object(new_key).copy_from(CopySource=copy_source)
    print(f"--> '{obj.key}' to '{new_key}'")

print(f"... {VERSION} of the frontend is now live in {ENVIRONMENT}.")
