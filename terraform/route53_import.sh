#!/bin/bash

hosted_zone=$(aws route53 list-hosted-zones --query 'HostedZones[0].Id' --output text | cut -d/ -f3)
echo "Importing Zone ID ${hosted_zone}"
terraform import aws_route53_zone.main ${hosted_zone}

echo "This is what I've Imported"
terraform state show aws_route53_zone.main
