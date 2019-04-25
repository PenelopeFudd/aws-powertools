#!/bin/bash

# Parse arguments:
VERBOSE=0
while getopts ":r:p:v" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi


if [[ "$VERBOSE" == 0 ]]; then
  aws $PROFILE $REGION configservice describe-config-rules | jq -r '.ConfigRules[] | select(.ConfigRuleState != "DELETING") | .ConfigRuleName'  
  exit 0
fi
if [[ "$VERBOSE" == 1 ]]; then
  aws $PROFILE $REGION configservice describe-config-rules 
  exit 0
fi
# {
#     "ConfigRules": [
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether ACM Certificates in your account are marked for expiration within the specified number of days. Certificates provided by ACM are automatically renewed. ACM does not automatically renew certificates that you import.", 
#             "ConfigRuleName": "acm-certificate-expiration-check", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-ernxli", 
#             "MaximumExecutionFrequency": "TwentyFour_Hours", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "ACM_CERTIFICATE_EXPIRATION_CHECK"
#             }, 
#             "InputParameters": "{\"daysToExpiration\":\"14\"}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::ACM::Certificate"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-ernxli"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether AWS CloudTrail is enabled in your AWS account. Optionally, you can specify which S3 bucket, SNS topic, and Amazon CloudWatch Logs ARN to use.", 
#             "ConfigRuleName": "cloudtrail-enabled", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-zj1mjm", 
#             "MaximumExecutionFrequency": "TwentyFour_Hours", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "CLOUD_TRAIL_ENABLED"
#             }, 
#             "InputParameters": "{}", 
#             "ConfigRuleId": "config-rule-zj1mjm"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether RDS DB instances have backups enabled. Optionally, the rule checks the backup retention period and the backup window.", 
#             "ConfigRuleName": "db-instance-backup-enabled", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-nowot1", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "DB_INSTANCE_BACKUP_ENABLED"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::RDS::DBInstance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-nowot1"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether provisioned DynamoDB throughput is approaching the maximum limit for your account. By default, the rule checks if provisioned throughput exceeds a threshold of 80% of your account limits.", 
#             "ConfigRuleName": "dynamodb-throughput-limit-check", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-pez7ce", 
#             "MaximumExecutionFrequency": "TwentyFour_Hours", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "DYNAMODB_THROUGHPUT_LIMIT_CHECK"
#             }, 
#             "InputParameters": "{\"accountWCUThresholdPercentage\":\"80\",\"accountRCUThresholdPercentage\":\"80\"}", 
#             "ConfigRuleId": "config-rule-pez7ce"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether EBS optimization is enabled for your EC2 instances that can be EBS-optimized.", 
#             "ConfigRuleName": "ebs-optimized-instance", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-kcwlyi", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "EBS_OPTIMIZED_INSTANCE"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::Instance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-kcwlyi"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether detailed monitoring is enabled for EC2 instances.", 
#             "ConfigRuleName": "ec2-instance-detailed-monitoring-enabled", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-gdi6un", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "EC2_INSTANCE_DETAILED_MONITORING_ENABLED"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::Instance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-gdi6un"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether your EC2 instances belong to a virtual private cloud (VPC). Optionally, you can specify the VPC ID to associate with your instances.", 
#             "ConfigRuleName": "ec2-instances-in-vpc", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-wgqjzh", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "INSTANCES_IN_VPC"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::Instance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-wgqjzh"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether EBS volumes are attached to EC2 instances. Optionally checks if EBS volumes are marked for deletion when an instance is terminated.", 
#             "ConfigRuleName": "ec2-volume-inuse-check", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-radqws", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "EC2_VOLUME_INUSE_CHECK"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::Volume"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-radqws"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether all EIP addresses allocated to a VPC are attached to EC2 instances or in-use ENIs.", 
#             "ConfigRuleName": "eip-attached", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-lvxvba", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "EIP_ATTACHED"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::EIP"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-lvxvba"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether EBS volumes that are in an attached state are encrypted. Optionally, you can specify the ID of a KMS key to use to encrypt the volume.", 
#             "ConfigRuleName": "encrypted-volumes", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-1jtelr", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "ENCRYPTED_VOLUMES"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::Volume"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-1jtelr"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether the account password policy for IAM users meets the specified requirements.", 
#             "ConfigRuleName": "iam-password-policy", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-t1bixy", 
#             "MaximumExecutionFrequency": "TwentyFour_Hours", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "IAM_PASSWORD_POLICY"
#             }, 
#             "InputParameters": "{\"MinimumPasswordLength\":\"14\",\"RequireLowercaseCharacters\":\"true\",\"RequireNumbers\":\"true\",\"PasswordReusePrevention\":\"24\",\"MaxPasswordAge\":\"90\",\"RequireUppercaseCharacters\":\"true\",\"RequireSymbols\":\"true\"}", 
#             "ConfigRuleId": "config-rule-t1bixy"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether IAM users are members of at least one IAM group.", 
#             "ConfigRuleName": "iam-user-group-membership-check", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-8wax9f", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "IAM_USER_GROUP_MEMBERSHIP_CHECK"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::IAM::User"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-8wax9f"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks that none of your IAM users have policies attached. IAM users must inherit permissions from IAM groups or roles.", 
#             "ConfigRuleName": "iam-user-no-policies-check", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-xde4qi", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "IAM_USER_NO_POLICIES_CHECK"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::IAM::User"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-xde4qi"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether high availability is enabled for your RDS DB instances.", 
#             "ConfigRuleName": "rds-multi-az-support", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-if8sey", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "RDS_MULTI_AZ_SUPPORT"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::RDS::DBInstance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-if8sey"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether storage encryption is enabled for your RDS DB instances.", 
#             "ConfigRuleName": "rds-storage-encrypted", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-l5zyqz", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "RDS_STORAGE_ENCRYPTED"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::RDS::DBInstance"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-l5zyqz"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether security groups that are in use disallow unrestricted incoming SSH traffic.", 
#             "ConfigRuleName": "restricted-ssh", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-a91l4m", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "INCOMING_SSH_DISABLED"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::EC2::SecurityGroup"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-a91l4m"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether the root user of your AWS account requires multi-factor authentication for console sign-in.", 
#             "ConfigRuleName": "root-account-mfa-enabled", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-huh2er", 
#             "MaximumExecutionFrequency": "TwentyFour_Hours", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "ROOT_ACCOUNT_MFA_ENABLED"
#             }, 
#             "ConfigRuleId": "config-rule-huh2er"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether logging is enabled for your S3 buckets.", 
#             "ConfigRuleName": "s3-bucket-logging-enabled", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-6qqjaq", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "S3_BUCKET_LOGGING_ENABLED"
#             }, 
#             "InputParameters": "{}", 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::S3::Bucket"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-6qqjaq"
#         }, 
#         {
#             "ConfigRuleState": "ACTIVE", 
#             "Description": "Checks whether S3 buckets have policies that require requests to use Secure Socket Layer (SSL).", 
#             "ConfigRuleName": "s3-bucket-ssl-requests-only", 
#             "ConfigRuleArn": "arn:aws:config:us-west-2:978708203214:config-rule/config-rule-vrcdix", 
#             "Source": {
#                 "Owner": "AWS", 
#                 "SourceIdentifier": "S3_BUCKET_SSL_REQUESTS_ONLY"
#             }, 
#             "Scope": {
#                 "ComplianceResourceTypes": [
#                     "AWS::S3::Bucket"
#                 ]
#             }, 
#             "ConfigRuleId": "config-rule-vrcdix"
#         }
#     ]
# }
