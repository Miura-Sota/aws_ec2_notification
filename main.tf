provider "aws" {
  region = "ap-northeast-1"
}

# 1. SNSトピックの作成（通知のハブ）
resource "aws_sns_topic" "ec2_alert" {
  name = "EC2-Alert-Topic"
}

# 2. SNSサブスクリプション（メールアドレスの登録）
resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.ec2_alert.arn
  protocol  = "email"
  endpoint  = "example@gmail.com" # あなたのアドレス
}

# 3. Lambda用のIAMロール（許可証）
resource "aws_iam_role" "lambda_role" {
  name = "EC2CheckLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 4. ロールに権限を付与（EC2を見る + SNSを送る + ログを出す）
resource "aws_iam_role_policy_attachment" "ec2_read" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "sns_publish" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# 5. Lambda関数の作成
resource "aws_lambda_function" "ec2_checker" {
  filename      = "lambda_function.zip" # 後ほど作成します
  function_name = "EC2StatusChecker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  timeout       = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.ec2_alert.arn
    }
  }
}

# 6. EventBridge（タイマー：毎日20時）
resource "aws_cloudwatch_event_rule" "every_day_20pm" {
  name                = "DailyEC2Check"
  schedule_expression = "cron(0 11 * * ? *)" # UTC 11:00 = JST 20:00
}

resource "aws_cloudwatch_event_target" "check_ec2_at_20pm" {
  rule      = aws_cloudwatch_event_rule.every_day_20pm.name
  target_id = "lambda"
  arn       = aws_lambda_function.ec2_checker.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_20pm.arn
}
