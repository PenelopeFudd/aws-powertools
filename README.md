# AWS Power Tools

Have you ever wanted to list all of the resources set up in your AWS account?  Or have you gotten so frustrated that you just wanted to delete everything and start over?  Then AWS Powertools are for you!  The commands 'aws-list-all.sh' and 'aws-delete-all.sh' do what they say on the tin, at least for dynamodb, gw, lbv2, asg, ebs-volumes, instance, lcs, sg, cloudformation, eip, kinesis, nat, sqs, cloudwatch-alarms, elasticache, lambda, rds, subnet, configservice, eni, lb, and vpc.  There are additional commands for delete s3 objects and buckets, but they're commented out in the 'aws-delete-all.sh' script because they're deleting a bit more than most people expect.

## Getting Started

If you can run 'aws-list-instances.sh -v -r us-east-2' and get a nice list of the instances in that region, all of the
'aws-list-*.sh' scripts should work, as well as all of the 'aws-delete-*.sh' scripts, with the exception of 'aws-delete-all.sh'.

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
