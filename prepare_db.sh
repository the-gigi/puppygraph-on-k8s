#!/bin/bash

# Variables
DEPLOYMENT_NAME="spark-iceberg"  # Name of the deployment
SQL_FILE="security_graph.sql"   # Name of the SQL script file
DESTINATION_PATH="/tmp/$SQL_FILE" # Destination path inside the pod

# Step 1: Find the Pod name
echo "Finding pod for deployment $DEPLOYMENT_NAME..."
POD_NAME=$(kubectl get pods -l app=$DEPLOYMENT_NAME -o jsonpath="{.items[0].metadata.name}")

if [ -z "$POD_NAME" ]; then
  echo "Error: No pod found for deployment $DEPLOYMENT_NAME"
  exit 1
fi
echo "Pod found: $POD_NAME"

# Step 2: Copy the SQL file to the pod
echo "Copying $SQL_FILE to pod $POD_NAME at $DESTINATION_PATH..."
kubectl cp "$SQL_FILE" "$POD_NAME:$DESTINATION_PATH"
if [ $? -ne 0 ]; then
  echo "Error: Failed to copy $SQL_FILE to pod $POD_NAME"
  exit 1
fi
echo "File copied successfully."

# Step 3: Execute the SQL file inside the pod
echo "Executing $SQL_FILE on pod $POD_NAME using spark-sql..."
kubectl exec -it "$POD_NAME" -- spark-sql -f "$DESTINATION_PATH"
if [ $? -ne 0 ]; then
  echo "Error: Failed to execute $SQL_FILE on pod $POD_NAME"
  exit 1
fi

echo "SQL script executed successfully!"