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

# Wait for the EBS volume to be attached and format/mount it
EBS_DEVICE="/dev/xvdf"
MOUNT_POINT="/data/mysql"

# Wait for the device to be available
while [ ! -e $EBS_DEVICE ]; do
  echo "Waiting for EBS volume to be attached..."
  sleep 5
done

# Create mount point
sudo mkdir -p $MOUNT_POINT

# Check if the volume is already formatted
if sudo file -s $EBS_DEVICE | grep -q "/dev/xvdf: data"; then
  # Format the volume if it's not already formatted
  sudo mkfs -t ext4 $EBS_DEVICE
fi

# Mount the volume
sudo mount $EBS_DEVICE $MOUNT_POINT

# Add to fstab for persistent mounting
echo "$EBS_DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Set proper ownership for Docker MySQL
sudo chown -R 999:999 $MOUNT_POINT

# Run MySQL container with bind mount to EBS-backed directory
sudo docker run --name mysql-server \
  -v /data/mysql:/var/lib/mysql \
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