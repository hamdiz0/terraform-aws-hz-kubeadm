
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo $AZ | sed 's/.$//')
HOST_NAME=${HOST_TYPE:-worker}.ip-$PRIVATE_IP.$INSTANCE_ID

# Set hostname
hostnamectl set-hostname $HOST_NAME

# tag the instance

aws ec2 create-tags \
  --region $REGION \
  --resources $INSTANCE_ID \
  --tags Key=Name,Value=$HOST_TYPE.ip-$PRIVATE_IP

# configure kubelet for seamless intgeration with aws
echo "KUBELET_EXTRA_ARGS=--provider-id=aws:///$AZ/$INSTANCE_ID --node-ip=$PRIVATE_IP --cloud-provider=external" | tee /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet