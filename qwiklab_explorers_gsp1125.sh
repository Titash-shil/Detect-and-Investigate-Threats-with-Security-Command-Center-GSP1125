
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud projects get-iam-policy $(gcloud config get-value project) \
    --format=json > policy.json

jq '{ 
  "auditConfigs": [ 
    { 
      "service": "cloudresourcemanager.googleapis.com", 
      "auditLogConfigs": [ 
        { 
          "logType": "ADMIN_READ" 
        } 
      ] 
    } 
  ] 
} + .' policy.json > updated_policy.json

gcloud projects set-iam-policy $(gcloud config get-value project) updated_policy.json

gcloud services enable securitycenter.googleapis.com --project=$DEVSHELL_PROJECT_ID

sleep 20

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:demouser1@gmail.com --role=roles/bigquery.admin

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/cloudresourcemanager.projectIamAdmin 2>/dev/null

gcloud compute instances create instance-1 \
--zone=$ZONE \
--machine-type=e2-medium \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
--metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD \
--scopes=https://www.googleapis.com/auth/cloud-platform --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230912,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced

gcloud dns --project=$DEVSHELL_PROJECT_ID policies create dns-test-policy --description="Qwiklab" --networks="default" --private-alternative-name-servers="" --no-enable-inbound-forwarding --enable-logging

sleep 30

gcloud compute ssh instance-1 --zone=$ZONE --tunnel-through-iap --project "$DEVSHELL_PROJECT_ID" --quiet --command "gcloud projects get-iam-policy \$(gcloud config get project) && curl etd-malware-trigger.goog"
