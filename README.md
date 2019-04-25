# AWS Powertools

* Have you ever wanted to list all of the resources set up in your AWS account?

* Have you gotten so frustrated that you just wanted to delete everything in your AWS account and start over?

Then AWS Powertools are for you!

The commands 'aws-list-all.sh' and 'aws-delete-all.sh' do what they say on the tin, at least for:
* AutoScaling groups
* AutoScaling Launch Configurations
* CloudFormation templates
* Cloudwatch alarms
* Configuration service entries
* DynamoDB tables
* EBS Volumes
* EC2 Instances
* Elasticache instances
* Elastic IPs
* Elastic Network Interfaces
* ELB load balancers
* ELB V2
* Kinesis streams
* Lambda functions
* RDS databases
* SQS queues
* VPC Gateways
* VPC NAT gateways
* VPC Security Groups
* VPC Subnets
* VPCs

There's a command for deleting S3 buckets, but it's commented out in the 'aws-delete-all.sh' script.

## Getting Started

If the command 'aws-list-instances.sh -v -r us-east-2' works, then all of the scripts should work except for 'aws-delete-all.sh', since it uses [GNU parallel](https://www.gnu.org/s/parallel/) to speed up the Apocalypse (not to be confused with the Alpacalypse, where the world is destroyed by an invasion of [alpacas](https://en.wikipedia.org/wiki/Alpaca)).

### Prerequisites

These files are bash scripts, using the AWS command line tool 'aws', the 'jq' command, and GNU Parallel.

```
$ aws-delete-all.sh
Usage: ./aws-delete-all.sh [-p profile] [-r region] [-c confirmstring] [-v]

__        ___    ____  _   _ ___ _   _  ____ _
\ \      / / \  |  _ \| \ | |_ _| \ | |/ ___| |
 \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _| |
  \ V  V / ___ \|  _ <| |\  || || |\  | |_| |_|
   \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____(_)


  This command will **DELETE** all[1] resources in the specified
  region of the given AWS account.

  [1]: Here, 'all' means:
      Autoscaling groups
      Instances
      Launch configurations
      ELB load balancers
      ELBv2/ALB load balancers
      Elastic Network Interfaces
      Virtual Private Clusters (VPC)
      Subnets
      Security groups
      Gateways

Options:
  -p default: specify the profile for authentication and region selection (see /home/chowes/.aws/config)
  -r region: specify the region, eg. us-west-2.  The default region comes from the profile.
  -v: run in verbose mode
  -c confirmstring: confirm you actually want to delete everything.
      Run this to confirm:
        ./aws-delete-all.sh -c 2019-04-24-18:17

```

### Installing


Installing jq, GNU parallel, and the AWS CLI:

```
$ sudo yum install -y awscli jq parallel
```

Example:
```
$ aws-list-instances.sh -r us-east-2 -v
# aws  --region us-east-2 ec2 describe-instances
InstanceId           Name               KeyName      PublicIpAddress  PrivateIpAddress  LaunchTime           InstanceType  State
i-003a865dcfa45cf64  "Sample Instance"  ssh-keypair  18.191.24.147    172.31.29.207     2019-04-23T19:42:34  t2.micro      running
```

## Authors

* **Charles Howes** - *Initial work*
