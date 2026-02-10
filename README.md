# aws_ec2_notification

## 概要
EC2の消し忘れによる予期せぬ課金を防ぐための自動通知仕組みです。
毎日20時（JST）に稼働中のインスタンスをチェックし、存在すればSNSを通じてメール通知を行います。

## 技術スタック
- Terraform (IaC)
- AWS Lambda (Python 3.14)
- Amazon EventBridge (Cron)
- Amazon SNS

## 構築の背景
AWS SAAの学習にあたり、ハンズオン後のリソース消し忘れを防ぐために作成しました。
IaCも触ったことなかったので、Terraformで作ってみました。
