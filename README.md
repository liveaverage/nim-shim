
- [Usage](#usage)
- [Testing (Sagemaker)](#testing--sagemaker-)
- [Testing (Local)](#testing--local-)
  * [Health](#health)
  * [Invocation](#invocation)
    + [Non-streaming](#non-streaming)
    + [Streaming](#streaming)

## Preparation
If needed, customize the the parameters passed to the `launch.sh` call to ensure proper mapping of frontend/backend ports and source entrypoint.

```bash
git clone https://github.com/liveaverage/nim-shim && cd nim-shim

### Set your NGC API Key
export NGC_API_KEY=nvapi-your-api-key

export SRC_IMAGE_PATH=nvcr.io/nim/meta/llama3-70b-instruct:latest
export SRC_IMAGE_NAME="${SRC_IMAGE_PATH##*/}"
export SRC_IMAGE_NAME="${SRC_IMAGE_NAME%%:*}"
export DST_REGISTRY=your-registry.dkr.ecr.us-west-2.amazonaws.com/nim-shim

docker login nvcr.io
docker login ${DST_REGISTRY}
docker pull ${SRC_IMAGE}

envsubst < Dockerfile > Dockerfile.nim
docker build -f Dockerfile.nim -t ${DST_REGISTRY}:${SRC_IMAGE_NAME} .
docker push ${DST_REGISTRY}:${SRC_IMAGE_NAME}

export SG_EP_NAME="nim-llm-${SRC_IMAGE_NAME}"
export SG_EP_CONTAINER=${DST_REGISTRY}:${SRC_IMAGE_NAME}
export SG_INST_TYPE=ml.g5.4xlarge	
export SG_EXEC_ROLE_ARN="arn:aws:iam::YOUR-ARN-ROLE:role/service-role/AmazonSageMakerServiceCatalogProductsUseRole"
export SG_CONTAINER_STARTUP_TIMEOUT=850 #in seconds -- adjust depending on dynamic or S3 model pull
```

## Usage

## Testing (Sagemaker)

```bash
# Generate model JSON
envsubst < templates/sg-model.template > sg-model.json

# Create Model
aws sagemaker create-model \
    --cli-input-json file://sg-model.json

# Create Endpoint Config
aws sagemaker create-endpoint-config \
    --endpoint-config-name $SG_EP_NAME \
    --production-variants "$(envsubst < templates/sg-prod-variant.template)"

# Create Endpoint
aws sagemaker create-endpoint \
    --endpoint-name $SG_EP_NAME \
    --endpoint-config-name $SG_EP_NAME
```

## Testing (Local)

```bash
docker run -it --rm -e NGC_API_KEY=$NGC_API_KEY -p 8080:8080 nim-shim
```

### Health
```bash
curl -X GET 127.0.0.1:8080/ping -vvv
```

### Invocation

#### Non-streaming
```bash
curl -X 'POST' \
'http://127.0.0.1:8080/invocations' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
"model": "meta/llama3-8b-instruct",
"messages": [
{
"role":"user",
"content":"Hello! How are you?"
},
{
"role":"assistant",
"content":"Hi! I am quite well, how can I help you today?"
},
{
"role":"user",
"content":"Can you write me a song?"
}
],
"max_tokens": 32
}'
```

#### Streaming
```bash
curl -X 'POST' \
'http://127.0.0.1:8080/invocations' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
	-H 'Content-Type: text/event-stream' \
    -d '{
"model": "meta/llama3-8b-instruct",
"messages": [
{
"role":"user",
"content":"Hello! How are you?"
},
{
"role":"assistant",
"content":"Hi! I am quite well, how can I help you today?"
},
{
"role":"user",
"content":"Can you write me a song featuring 90s grunge rock vibes?"
}
],
"max_tokens": 320,
"stream": true
}'
```

## Cleanup

Purge your Sagemaker resources (if desired) between runs:
```bash
# Cleanup Sagemaker
sg_delete_resources() {
    local endpoint_name=$1
    # Delete endpoint
    aws sagemaker delete-endpoint --endpoint-name $endpoint_name || true
    # Wait for the endpoint to be deleted
    aws sagemaker wait endpoint-deleted --endpoint-name $endpoint_name || true
    # Delete endpoint config
    aws sagemaker delete-endpoint-config --endpoint-config-name $endpoint_name || true
    # Delete model
    aws sagemaker delete-model --model-name $endpoint_name || true
}

# Delete existing resources
sg_delete_resources $SG_EP_NAME
```
