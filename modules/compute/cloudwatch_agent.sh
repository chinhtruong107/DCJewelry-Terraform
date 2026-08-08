#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wget
wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "agent": { "metrics_collection_interval": 60 },
  "metrics": {
    "namespace": "DCJewelry/EC2",
    "append_dimensions": { "InstanceId": "${aws:InstanceId}" },
    "aggregation_dimensions": [["InstanceId"]],
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "ignore_file_system_types": ["sysfs", "devtmpfs", "tmpfs", "overlay"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/syslog", "log_group_name": "/dcjewelry/ec2", "log_stream_name": "{instance_id}/syslog" },
          { "file_path": "/var/log/auth.log", "log_group_name": "/dcjewelry/ec2", "log_stream_name": "{instance_id}/auth" },
          { "file_path": "/var/log/cloud-init-output.log", "log_group_name": "/dcjewelry/ec2", "log_stream_name": "{instance_id}/cloud-init" }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
