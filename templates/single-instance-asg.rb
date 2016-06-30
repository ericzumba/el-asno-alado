CloudFormation do
  AWSTemplateFormatVersion '2010-09-09'
  Description "Simple ASG"

  adhoc_params = eval(external_parameters.fetch(:adhoc_params, '{}'))
  tags.merge! adhoc_params[:tags] 

  Resource('ASG') do
    Type 'AWS::AutoScaling::AutoScalingGroup'
    Property('AvailabilityZones', availability_zones)
    Property('LaunchConfigurationName', Ref('LaunchConfig'))
    Property('MinSize', '1')
    Property('MaxSize', '1')
    Property('VPCZoneIdentifier', subnets)
    Property('TerminationPolicies', termination_policies)
    Property('HealthCheckGracePeriod',  health_check['grace_period'])
    Property('HealthCheckType',  health_check['type'])
    Property('MetricsCollection', [{
      'Granularity' => '1Minute',
      'Metrics' => [
        'GroupDesiredCapacity',
        'GroupInServiceInstances',
        'GroupMaxSize',
        'GroupMinSize',
        'GroupPendingInstances',
        'GroupTerminatingInstances',
        'GroupTotalInstances'
      ]
    }])
    Property('Tags', tags.map { |name, value| { 'Key' => name, 'Value' => value, 'PropagateAtLaunch' => true }})
  end

  Resource('LaunchConfig') do
    Type 'AWS::AutoScaling::LaunchConfiguration'
    Property('KeyName', key_name)
    Property('ImageId', image_id)
    Property('UserData', FnBase64(File.open(user_data).read))
    Property('SecurityGroups', security_groups)
    Property('InstanceType', instance_type)
    Property('AssociatePublicIpAddress', public_ip)
  end
end
