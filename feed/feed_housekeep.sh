#!/bin/bash

# Define the SNS topic ARN
SNS_TOPIC_ARN="arn:aws:sns:ap-southeast-1:891377130731:Live-Feed"

# Get all SQS queues
echo "Listing all SQS queues..."
SQS_QUEUES=$(aws sqs list-queues --query 'QueueUrls[]' --output text | tr '\t' '\n' | grep -vi "Audit-Action")

if [ -z "$SQS_QUEUES" ]; then
  echo "No SQS queues found."
  exit 0
fi

# Get all pod names from Kubernetes
echo "Listing all Kubernetes pods..."
POD_NAMES=$(/usr/local/bin/kubectl get pods -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep "voucher-app-feed")

if [ -z "$POD_NAMES" ]; then
  echo "No pods found in the cluster."
  exit 0
fi

# Loop through each SQS queue URL
for QUEUE_URL in $SQS_QUEUES; do
  # Extract queue name from URL (assuming the last part of the URL is the queue name)
  QUEUE_NAME=$(echo $QUEUE_URL | awk -F/ '{print $NF}')

  # Check if the queue name exists in the pod names
  if echo "$POD_NAMES" | grep -wq "$QUEUE_NAME"; then
    echo "Queue $QUEUE_NAME has a corresponding pod. Skipping deletion."
  else
    echo "Queue $QUEUE_NAME does not have a corresponding pod. Deleting..."

    # Delete the queue
    aws sqs delete-queue --queue-url "$QUEUE_URL"

    if [ $? -eq 0 ]; then
      echo "Queue $QUEUE_URL deleted successfully."

      # Now unsubscribe from the SNS topic
      echo "Unsubscribing from SNS topic..."
      SUBSCRIPTION_ARN=$(aws sns list-subscriptions-by-topic --topic-arn "$SNS_TOPIC_ARN" --query "Subscriptions[?Endpoint=='arn:aws:sqs:ap-southeast-1:891377130731:$QUEUE_NAME'].SubscriptionArn" --output text)

      # Check if the subscription ARN is not empty
      if [ -n "$SUBSCRIPTION_ARN" ]; then
        # Unsubscribe from the SNS topic
        aws sns unsubscribe --subscription-arn "$SUBSCRIPTION_ARN"

        if [ $? -eq 0 ]; then
          echo "Unsubscribed $QUEUE_NAME successfully."
        else
          echo "Failed to unsubscribe $QUEUE_NAME."
        fi
      else
        echo "No subscription found for $QUEUE_NAME."
      fi
    else
      echo "Failed to delete queue $QUEUE_URL."
    fi
  fi
done

echo "Finished processing all queues."
