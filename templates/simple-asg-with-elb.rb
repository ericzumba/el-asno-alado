CloudFormation do
  AWSTemplateFormatVersion '2010-09-09'
  Description 'Simple ASG with ELB'

  adhoc_params = eval(external_parameters.fetch(:adhoc_params, '{}'))
  tags.merge! adhoc_params[:tags] 

  Resource('ELB') do
    Type 'AWS::ElasticLoadBalancing::LoadBalancer'
    Property('HealthCheck', {
      'HealthyThreshold'   => health_check['healthy_threshold'],
      'Interval'           => health_check['interval'], 
      'Target'             => health_check['target'], 
      'Timeout'            => health_check['timeout'], 
      'UnhealthyThreshold' => health_check['unhealthy_threshold']
    })
    Property('Listeners', [{
      'InstancePort'     => elb['instance_port'],
      'LoadBalancerPort' => elb['balancer_port'],
      'Protocol'         => 'HTTP'
    }])
    Property('CrossZone', true)
    Property('Scheme', 'internal')
    Property('SecurityGroups', security_groups) 
    Property('Subnets', subnets)
  end

  Resource('Route53') do 
    Type 'AWS::Route53::RecordSet'
    Property('HostedZoneId', dns['hosted_zone_id'])
    Property('Name', "#{adhoc_params[:StackName]}.#{dns['hosted_zone']}")
    Property('Type', dns['type'])
    Property('AliasTarget', {
      'HostedZoneId' =>  FnGetAtt("ELB", "CanonicalHostedZoneNameID"), 
      'DNSName' => FnGetAtt("ELB", "DNSName") 
    })
  end 

  Resource('ASG') do
    Type 'AWS::AutoScaling::AutoScalingGroup'
    Property('AvailabilityZones', availability_zones)
    Property('LaunchConfigurationName', Ref('LaunchConfig'))
    Property('MinSize', asg['min'])
    Property('MaxSize', asg['max'])
    Property('VPCZoneIdentifier', subnets)
    Property('TerminationPolicies', termination_policies)
    Property('HealthCheckGracePeriod',  health_check['grace_period'])
    Property('HealthCheckType',  'ELB')
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
    Property('LoadBalancerNames', [Ref('ELB')])
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
