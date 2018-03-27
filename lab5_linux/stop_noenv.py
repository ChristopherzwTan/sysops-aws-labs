#!/usr/bin/python

import boto3

instances = [i for i in boto3.resource('ec2', region_name='us-west-2').instances.all()]

bad_instances = []

# Print instance_id of instances that do not have a Tag of Key='Foo'
for i in instances:
  if ('Environment' not in [t['Key'] for t in i.tags] and i.subnet_id == "subnet-8c5991c7"):
    bad_instances.append(i.instance_id)
    print "Shutting down instance " + i.instance_id

boto3.resource('ec2').instances.filter(InstanceIds=bad_instances).stop()
