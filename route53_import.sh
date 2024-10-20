#!/bin/bash

# Set your domain name (no spaces around the =)
domain_name="ashley.solutions"

# Get the hosted zone ID
hosted_zone=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`ashley.solutions.`].Id' --output text | cut -d/ -f3)

# Check if the hosted zone ID was retrieved
if [ -z "$hosted_zone" ]; then
    echo "Hosted zone ID not found."
    exit 1
fi

echo "Importing Zone ID ${hosted_zone}"
terraform import aws_route53_zone.main "${hosted_zone}"

# Write the domain name to terraform.tfvars (use the variable value)
echo "domain_name = \"${domain_name}\"" > terraform.tfvars

echo "This is what I've Imported"
terraform state show aws_route53_zone.main
