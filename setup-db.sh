#!/bin/bash -xe
# Update system
sudo yum update -y

# Install Docker
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install and configure SSM agent
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Create Docker volume for MySQL data
sudo docker volume create mysql-data

# Run MySQL container
sudo docker run --name mysql-server \
  -v mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=${DBPassword} \
  -e MYSQL_DATABASE=${DBName} \
  -e MYSQL_USER=${DBUsername} \
  -e MYSQL_PASSWORD=${DBPassword} \
  -p 3306:3306 \
  --restart unless-stopped \
  -d mysql:8.0

# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
sudo cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": ["swap_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker",
            "log_group_name": "/aws/ec2/mysql/docker",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl start amazon-cloudwatch-agent.service