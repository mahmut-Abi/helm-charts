# Kafka Helm Chart

This chart deploys Apache Kafka in KRaft mode without ZooKeeper.

## KRaft Mode

Kafka 3.3+ supports running without ZooKeeper using the KRaft consensus protocol.
Each pod runs as both a broker and a controller (combined mode).

## Quick Start

```bash
helm install kafka ./kafka
```

For a production deployment with 3 replicas and persistent storage:

```bash
helm install kafka ./kafka \
  --set replicas=3 \
  --set persistence.enabled=true \
  --set persistence.size=100Gi
```

## SASL Authentication

Enable SASL/PLAIN authentication for client and inter-broker communication:

```bash
helm install kafka ./kafka \
  --set auth.enabled=true \
  --set auth.interBrokerUser=kafka \
  --set auth.interBrokerPassword=secret123 \
  --set 'auth.clientUsers[0].user=admin' \
  --set 'auth.clientUsers[0].password=admin-secret'
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicas` | Number of broker replicas | `3` |
| `image.repository` | Kafka image repository | `apache/kafka` |
| `image.tag` | Kafka image tag | `3.9.0` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size per broker | `50Gi` |
| `auth.enabled` | Enable SASL authentication | `false` |
| `service.nodePort` | NodePort for external access (0 = disabled) | `0` |
| `heapOpts` | JVM heap options | `-Xmx2G -Xms1G` |
| `extraServerProperties` | Additional server.properties entries | `{}` |

## Connecting

Bootstrap server (internal):

```
<release>-kafka-headless.<namespace>.svc.cluster.local:9092
```

Individual broker endpoints:

```
<release>-kafka-0.<release>-kafka-headless.<namespace>.svc.cluster.local:9092
<release>-kafka-1.<release>-kafka-headless.<namespace>.svc.cluster.local:9092
...
```