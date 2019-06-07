# Ci::Connector

| :warning: The scripts in the `bin` folder are not inculded in the docker image, but released via a ConfigMap. After changing them, you need to run `make release-notification` to deploy your local version of the scripts, so be careful that your local version is up to date.
| --- |

## Usage

### Using the docker image

Sample script

./main.rb

```ruby
#!/usr/bin/env ruby

require "CI/connector"

conn = CI::Connector.from_env()
conn.on('github.pull_request') do |event|
  if event['action'] == 'closed'
    conn.logger.info "Close PR #{event['number']}"
  end
end

trap("TERM") { conn.stop }
trap("INT") { conn.stop }

```

### Docker deployment

Minimal Dockerfile


./Dockerfile

```Dockerfile
FROM docker.k8s.jobteaser.net/coretech/ci-connector:<TAG>
COPY main.rb /usr/src/app/main.rb
```

```bash
export KAFKA_BROKERS=<kafka>
export KAFKA_CONSUMER_GROUP=<groupname>

docker run -d -e KAFKA_BROKERS -e KAFKA_CONSUMER_GROUP <image_name>
```

### Kubernetes deployment

```
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ci-connector-abcd
  annotations:
  labels:
    app: ci-connector
    release: ci-connector-abcd
spec:
  replicas: 1
  selector:
    matchLabels:
        app: ci-connector
        release: ci-connector-abcd
  template:
    metadata:
      labels:
        app: ci-connector
        release: ci-connector-abcd
    spec:
      containers:
      - name: connector
        image: docker.k8s.jobteaser.net/coretech/ci-connector:latest
        imagePullPolicy: Always
        env:
        - name: KAFKA_BROKERS
          value: "kafka:9092"
        - name: KAFKA_CONSUMER_GROUP
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels.release
        resources:
          limits:
            cpu: "1"
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /usr/src/app
      volumes:
      - name: config
        configMap:
          name: ci-connector-abcd
          items:
          - key: main.rb
            path: main.rb
            mode: 511

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ci-connector-abcd
data:
  main.rb: |
    #!/usr/bin/env ruby

    require "CI/connector"

    conn = CI::Connector.from_env()
    conn.on('github.pull_request') do |event|
      if event['action'] == 'closed'
        conn.logger.info "Close PR #{event['number']}"
      end
    end

    trap("TERM") { conn.stop }
    trap("INT") { conn.stop }

```
