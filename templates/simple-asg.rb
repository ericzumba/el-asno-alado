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
    Property('MaxSize', '3')
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

  comparisons = { 
    '>'   => 'GreaterThanThreshold', 
    '>='  => 'GreaterThanOrEqualToThreshold',
    '<'   => 'LessThanThreshold',
    '<='  => 'LessThanOrEqualToThreshold'
  }

  scaling.each do |name, policy| 
    policy_name = "Scale#{ name.capitalize }Policy"
    alarm_name = "#{ policy['metric'] }#{ name.capitalize }"
    trigger_period = policy['period'] * policy['times']

    alarm_description = "Scale #{ name }" +
      " if #{ policy['metric'] } #{ policy['comparison'] } #{ policy['threshold'] }" +
      " for #{ trigger_period / 60 } minutes"

    Resource(policy_name) do
      Type 'AWS::AutoScaling::ScalingPolicy'
      Property('AdjustmentType', 'ChangeInCapacity')
      Property('AutoScalingGroupName', Ref('ASG'))
      Property('Cooldown', policy['wait'])
      Property('ScalingAdjustment', policy['adjustment'])
    end

    Resource(alarm_name) do
      Type 'AWS::CloudWatch::Alarm'
      Property('MetricName', policy['metric'])
      Property('AlarmDescription', alarm_description)
      Property('Threshold', policy['threshold'])
      Property('AlarmActions', [Ref(policy_name)])
      Property('ComparisonOperator', comparisons[policy['comparison']])
      Property('Namespace', 'AWS/EC2')
      Property('Statistic', policy['statistic'])
      Property('Period', policy['period'])
      Property('EvaluationPeriods', policy['times'])
      Property('Dimensions', [{
        'Name' => 'AutoScalingGroupName',
        'Value' => Ref('ASG')
      }])
    end 
  end
end
