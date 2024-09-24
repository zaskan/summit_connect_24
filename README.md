## Playing with Opentelemetry and Kafka 

~~~
podman network create otel-network
podman-compose up -d 
~~~
Opentelemetry could fail if kafka is not ready yet - need to fix that. Repeat the command if it fails

Write in the topic with:

~~~
curl -X POST http://localhost:4318/v1/traces -H "Content-Type: application/json" -d @trace.json
~~~
