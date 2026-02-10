import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    topic_arn = os.environ['SNS_TOPIC_ARN']
    
    response = ec2.describe_instances()
    running_ids = [i['InstanceId'] for r in response['Reservations'] 
                   for i in r['Instances'] if i['State']['Name'] == 'running']
    
    if running_ids:
        message = f"⚠️ 警告: 以下のEC2が起動中です。不要なら停止してください: {running_ids}"
        sns.publish(
            TopicArn=topic_arn,
            Subject="AWS EC2 消し忘れアラート",
            Message=message
        )
        return "Alert sent"
    
    return "No running instances"