

## Preparation
If needed, customize the the parameters passed to the `launch.sh` call to ensure proper mapping of frontend/backend ports and source entrypoint.

```
curl -L https://gist.github.com/liveaverage/197557adc5b4842cc7509027fa771a1c/raw/Dockerfile > Dockerfile
docker build -t nim-shim-sg:latest .
```

## Usage

```bash
export NGC_API_KEY=nvapi-your-api-key
docker run -it --rm -e NGC_API_KEY=$NGC_API_KEY -p 8080:8080 nim-shim
```

## Testing (Sagemaker)
## Testing (Local)

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
