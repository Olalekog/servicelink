#!/bin/bash
set -euo pipefail

# Requires NAME_TAG and IMAGE_REF in the environment. Resolves the target
# instance ID dynamically from its Name tag (set by Terraform as
# "<project_name>-<workspace>") rather than a stored/hardcoded instance ID, so
# replacing the instance never requires updating anything here. Runs the
# deploy as an SSM RunShellScript command rather than SSH, then polls for
# completion and fails the step if the remote script didn't succeed.

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$NAME_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
  echo "No running instance found with tag Name=$NAME_TAG" >&2
  exit 1
fi

echo "Resolved $NAME_TAG -> $INSTANCE_ID"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"docker pull $IMAGE_REF\",\"(docker rm -f servicelink || true)\",\"docker run -d --name servicelink --restart unless-stopped -p 8080:8080 $IMAGE_REF\"]" \
  --query "Command.CommandId" --output text)

echo "SSM command ID: $COMMAND_ID"

STATUS="Pending"
for _ in $(seq 1 30); do
  STATUS=$(aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" \
    --query "Status" --output text 2>/dev/null || echo "Pending")
  case "$STATUS" in
    Pending | InProgress | Delayed) sleep 5 ;;
    *) break ;;
  esac
done

echo "Final status: $STATUS"
echo "--- stdout ---"
aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query "StandardOutputContent" --output text
echo "--- stderr ---"
aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query "StandardErrorContent" --output text

[ "$STATUS" = "Success" ]
