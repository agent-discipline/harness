# 메시징 방식 분기표

[service-communication.md](service-communication.md) 2절에서 메시지(Outbox + 메시지 브로커 + Inbox)를 고른 뒤, 어느 브로커를 쓸지 정할 때 읽는다. 메시지를 쓸지 말지, Outbox와 Inbox, 받는 쪽의 멱등은 그 문서가 정하므로 여기서는 되풀이하지 않는다. 줄의 형식과 근거의 종류, 줄이 없거나 부딪힐 때의 절차는 [ROUTING.md](ROUTING.md)에 있다.

- **근거**: 이 문서의 근거는 모두 사용자 판단과 일반 지식(공식 문서)이다. 메시징 방식을 직접 잰 실측은 없어서, 크기가 있는 얻는 것과 내주는 것에는 모두 "잴 것: 메시징 실험의 ○○"를 붙였다. 메시징 실험은 다음 작업이다.
- **전제**: 집 서버에서 브로커를 직접 운영한다.
- **낱말**: 다시 읽기 — 받는 쪽이 이미 읽은 지난 메시지를 다시 읽는 것. 키 순서 — 같은 키(주문 번호 등)의 메시지를 보낸 순서대로 처리하는 것. 라우팅 — 메시지마다 받는 곳을 브로커가 고르는 것. 건별 재시도와 실패분 모으기 — 처리하지 못한 메시지를 하나씩 다시 보내고, 정한 횟수를 넘긴 것을 따로 모으는 것(dead letter). Redis Streams, RabbitMQ stream, NATS JetStream은 제품의 이름이다.

## 1. 어느 방식을 쓰나

위에서부터 차례로 묻고, 처음 걸리는 줄의 선택을 따른다. 아래 줄의 상황은 위 줄에 들지 않는다는 것을 앞에 깔고 있다.

| 상황 | 선택 | 얻는 것 | 내주는 것 | 근거 | 확인한 날 |
|---|---|---|---|---|---|
| 이미 운영하는 브로커가 필요한 기능(다시 읽기, 키 순서, 라우팅, 건별 재시도와 실패분 모으기)을 지원한다. Redis는 아래 Redis Streams 줄의 조건(보관할 양이 그 Redis의 메모리에 들어가고, 마지막 몇 건을 잃어도 된다)을 채울 때만 여기에 든다 | 이미 운영하는 그 브로커의 그 기능을 쓴다. 브로커를 늘리지 않는다 | 운영할 브로커가 하나다 | 그 기능에 가장 맞는 도구가 아닐 수 있다(크기는 잴 것) | 사용자 판단 2026-11-22 · 일반 지식(그 기능이 있다): Kafka share group의 레코드별 ack와 전달 횟수([Kafka 설계](https://kafka.apache.org/44/design/design/)), dead-letter queue(`share.version` 2 이상, [Kafka 운영](https://kafka.apache.org/44/operations/basic-kafka-operations/)) · RabbitMQ stream의 다시 읽기([Streams](https://www.rabbitmq.com/docs/streams)) · NATS JetStream의 다시 읽기([JetStream](https://docs.nats.io/nats-concepts/jetstream), [Reading back](https://docs.nats.io/learn/jetstream/reading-back)) · Redis Streams의 범위 읽기와 전달 횟수([Redis Streams](https://redis.io/docs/latest/develop/data-types/streams/)) · 잴 것: 메시징 실험의 같은 기능을 방식마다 썼을 때의 처리량과 지연 | 2026-11-22 |
| 위 줄에 들지 않는다(운영하는 브로커가 없거나, 그것이 필요한 기능을 지원하지 않는다). 받는 쪽이 지난 메시지를 다시 읽어야 한다(나중에 생긴 받는 쪽이 처음부터 읽는다, 버그를 고친 뒤 다시 처리한다). 또는 같은 키의 메시지가 보낸 순서대로 처리되어야 한다 | Kafka | 읽어도 지워지지 않고, 토픽마다 정한 보관 기간 동안 몇 번이고 다시 읽는다. 받는 쪽이 읽는 위치(offset)를 되돌려 다시 처리한다. 같은 키의 메시지는 같은 파티션에 쓰이고, 그 파티션은 쓰인 순서대로 읽힌다. 받는 쪽 그룹(consumer group)마다 따로 읽는다 | 순서는 파티션 안에서만 지켜진다. 한 그룹 안에서 한 파티션은 한 소비자만 읽어, 한 그룹의 병렬 소비자는 파티션 수를 넘지 못한다(share group은 넘을 수 있으나 그때의 순서는 확인하지 않았다). 보관 기간만큼 디스크를 쓴다(크기는 잴 것) | 사용자 판단 2026-11-22(선택) · 일반 지식: [Kafka 소개](https://kafka.apache.org/intro/), [Kafka 설계](https://kafka.apache.org/44/design/design/) · 잴 것: 메시징 실험의 `acks=all`과 `acks=1`의 처리량과 지연, 브로커를 죽였을 때의 유실·중복 건수, 보관량에 따른 디스크 | 2026-11-22 |
| 위 두 줄에 들지 않고, 메시지마다 받는 곳이 달라진다(종류, 지역 같은 키나 헤더로 받는 곳을 고른다) | RabbitMQ (quorum queue + exchange + dead letter exchange) | exchange가 라우팅 키, 패턴, 헤더로 메시지를 보낼 큐를 고르거나(direct, topic, headers), 바인딩된 큐 모두에 보낸다(fanout). 건별 재시도와 실패분 모으기도 함께 얻는다: quorum queue는 재전달 횟수를 세고, 한도(4.0부터 기본 20)를 넘긴 메시지와 거절(`requeue=false`), TTL 만료, 길이 초과로 빠진 메시지를 dead letter exchange로 보낸다. quorum queue는 Raft로 복제한다 | 받는 쪽이 확인(ack)한 메시지는 큐에서 지워진다. 같은 큐에 소비자가 여럿이면 재전달이 순서를 바꿀 수 있다. 보내는 쪽이 확인(publisher confirm)을 받지 않은 메시지는 quorum queue도 지켜 주지 못한다. quorum queue는 큐의 메시지 색인을 메모리에 둬, 쌓일수록 메모리를 쓴다(크기는 잴 것) | 사용자 판단 2026-11-22(선택) · 일반 지식: [AMQP 개념](https://www.rabbitmq.com/tutorials/amqp-concepts), [Queues](https://www.rabbitmq.com/docs/queues), [Dead Letter Exchanges](https://www.rabbitmq.com/docs/dlx), [Quorum Queues](https://www.rabbitmq.com/docs/quorum-queues) · 잴 것: 메시징 실험의 publisher confirm과 수동 ack를 켠 설정과 자동 ack의 처리량과 지연, 브로커를 죽였을 때의 유실·중복 건수, 쌓였을 때의 메모리와 처리량 | 2026-11-22 |
| 위 세 줄에 들지 않고, 이미 Redis를 운영하고 있고, 보관할 양이 그 Redis의 메모리에 들어가며, Redis가 죽으면 마지막 몇 건을 잃어도 된다 | Redis Streams | 브로커를 새로 두지 않는다. consumer group으로 나눠 읽고, 처리 중인 메시지 목록(PEL)과 전달 횟수를 보고 멈춘 메시지를 다른 소비자가 가져가 다시 처리한다. ID 범위를 지정해 지난 메시지를 다시 읽는다 | 데이터가 메모리에 있어 보관할 양이 메모리 크기를 넘지 못한다. `MAXLEN`이나 `XTRIM`으로 잘라 낸 것은 다시 읽지 못한다. 복제가 비동기라 장애 조치 뒤 마지막 쓰기가 빠질 수 있고, 잃지 않으려면 AOF를 강한 fsync로 둬야 한다(처리량의 대가는 잴 것). 실패분 모으기는 기능이 아니라, 받는 쪽이 전달 횟수를 보고 다른 키로 옮기는 코드다 | 사용자 판단 2026-11-22(선택) · 일반 지식: [Redis Streams](https://redis.io/docs/latest/develop/data-types/streams/) · 잴 것: 메시징 실험의 `appendfsync everysec`과 `always`의 처리량과 지연, Redis를 죽였을 때의 유실 건수, 메시지 수에 따른 메모리 | 2026-11-22 |

위 어디에도 들지 않으면 고르지 않고 사용자에게 묻는다. 예를 들어 Redis만 운영하는데 잃으면 안 되는 작업(Redis Streams 줄의 조건에 들지 않는다), 특별히 필요한 기능이 없는 보통의 작업 넘기기가 여기에 든다. 운영하는 브로커가 둘 이상이고 둘 다 첫 줄(이미 운영하는 브로커)에 들 때도 묻는다. 위 어디에도 들지 않는 경우의 기본은 아직 두지 않았다(아래 "아직 줄이 없는 것").

이 표는 집 서버에서 브로커를 직접 운영한다는 전제다. 브로커를 직접 운영하지 않으려는 경우(관리형 브로커, 클라우드 큐)는 줄을 따르지 않고 사용자에게 묻는다. 클라우드 큐의 특성은 2절과 3절에 있다.

받는 쪽이 여럿인 것만으로는 방식을 정하지 않는다. Kafka, RabbitMQ, Redis Streams 모두 한 메시지를 여러 받는 쪽이 받게 할 수 있고, 받는 쪽이 늘 때 무엇이 늘어나는지는 3절의 "받는 쪽의 수" 행에 있다.

Redis Pub/Sub은 줄로 두지 않는다. 최대 한 번 전달이라, 받는 쪽이 꺼져 있거나 처리하지 못하면 그 메시지를 영영 잃는다([Redis Pub/Sub](https://redis.io/docs/latest/develop/pubsub/)).

## 2. 방식별 특성

선택이 없는 사실만 모은 표다. 분기표의 줄에 든 방식과 줄에 들지 않은 방식(NATS, 클라우드 큐)을 함께 견주어 보려고 둔다. 크기가 있는 것은 1절의 "잴 것"과 3절에 있다.

| 방식 | 할 수 있는 것 | 내주는 것 | 출처 |
|---|---|---|---|
| Kafka | 읽어도 지워지지 않고 보관 기간 동안 다시 읽는다 · 읽는 위치를 되돌린다 · 파티션 안의 순서 · 그룹마다 따로 읽는다 · share group은 레코드별 ack, 전달 횟수, dead-letter queue(`share.version` 2 이상) | 순서는 파티션 안에서만 · 일반 consumer group의 병렬 소비자는 파티션 수까지 | [소개](https://kafka.apache.org/intro/), [설계](https://kafka.apache.org/44/design/design/), [운영](https://kafka.apache.org/44/operations/basic-kafka-operations/) |
| RabbitMQ (queue) | exchange로 메시지마다 큐를 고른다 · 재전달 한도와 dead letter · quorum queue는 Raft로 복제 | ack된 메시지는 큐에서 지워진다 · 같은 큐에 소비자가 여럿이면 재전달이 순서를 바꿀 수 있다 · publisher confirm을 받지 않은 메시지는 지켜 주지 못한다 · 자동 ack는 안전하지 않다고 문서가 적는다 · quorum queue는 색인을 메모리에 둔다 | [AMQP 개념](https://www.rabbitmq.com/tutorials/amqp-concepts), [Queues](https://www.rabbitmq.com/docs/queues), [Dead Letter Exchanges](https://www.rabbitmq.com/docs/dlx), [Quorum Queues](https://www.rabbitmq.com/docs/quorum-queues), [Confirms](https://www.rabbitmq.com/docs/confirms) |
| RabbitMQ stream | 만료될 때까지 몇 번이고 다시 읽는다 · 받는 쪽이 몇이든 같은 메시지를 큐 하나에서 읽는다 · 메모리 부담이 적게 많은 데이터를 저장하도록 설계됐다 | 이 표에 적을 만큼 확인한 것이 없다 | [Streams](https://www.rabbitmq.com/docs/streams) |
| Redis Streams | 새 브로커 없이 · consumer group · 처리 중인 목록과 전달 횟수로 다시 처리 · 범위로 다시 읽기 | 메모리에 담긴다 · 잘라 낸 것은 다시 읽지 못한다 · 비동기 복제라 장애 조치 뒤 빠질 수 있다 · 잃지 않으려면 AOF를 강한 fsync로 · 실패분 모으기는 직접 짠다 | [Redis Streams](https://redis.io/docs/latest/develop/data-types/streams/) |
| NATS (core) | 서버가 메시지를 저장하지 않는다 · 연결된 구독자 모두에게 간다 | 최대 한 번 전달 · 꺼져 있거나 재시작 중이거나 아직 구독하지 않은 받는 쪽은 그 메시지를 받지 못하고, 서버는 나중을 위해 두지 않는다 | [Core NATS](https://docs.nats.io/nats-concepts/core-nats) |
| NATS JetStream | 최소 한 번 전달 · 재시작해도 남고 다시 읽는다 · ack가 제때 오지 않으면 다시 보낸다 · 보관 정책(Limits, Interest, WorkQueue) | dead-letter queue가 없다(`MaxDeliver`를 넘긴 메시지는 버려지고, 알림(advisory)을 받아 직접 옮긴다) · 메모리 저장은 재시작하면 잃는다 · 복제 1이면 그 서버가 죽을 때 함께 멈춘다 | [JetStream](https://docs.nats.io/nats-concepts/jetstream), [Streams](https://docs.nats.io/nats-concepts/jetstream/streams), [Retention policies](https://docs.nats.io/learn/jetstream/retention-policies), [Acknowledgment](https://docs.nats.io/learn/jetstream/acknowledgment), [Reading back](https://docs.nats.io/learn/jetstream/reading-back) |
| 클라우드 큐 (SQS, OCI Queue) | 브로커 서버를 운영하지 않는다(OCI Queue는 "fully managed serverless") · 받은 메시지는 정한 시간 동안 다른 소비자에게 보이지 않고, 지우지 않으면 다시 보인다 · 정한 횟수를 넘기면 dead-letter queue로 옮긴다 · SQS FIFO 큐는 순서를 지키고 큐에 중복을 들이지 않는다 | SQS 표준 큐는 같은 메시지가 두 번 오거나 순서가 바뀔 수 있다 · 메시지 크기와 보관 기간, FIFO 큐의 초당 호출 수에 제품의 한도가 있다(3절) · 망 밖으로 나가므로 TLS([service-communication.md](service-communication.md) 5절)와 사용료를 치른다 | [SQS 표준 큐](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/standard-queues.html), [SQS FIFO 큐](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-fifo-queues.html), [visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html), [SQS DLQ](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html), [OCI Queue](https://docs.oracle.com/en-us/iaas/Content/queue/overview.htm) |

## 3. 규모에 따라 달라지는 것

규모의 축마다 방식별로 무엇이 유리해지고 무엇이 문제가 되는지 방향만 적은 표다. 경계값은 적지 않고 "잴 것"으로 둔다. 숫자는 모두 제품이 문서에 적은 한도(실측이 아니라 사양)이고, 바꿀 수 있는 기본값은 그렇게 밝혔다.

| 축 | Kafka | RabbitMQ | Redis Streams | NATS | 클라우드 큐 |
|---|---|---|---|---|---|
| 초당 메시지 수 | 파티션을 늘려 그룹의 소비자를 늘린다(소비자 수는 파티션 수까지). `acks`를 느슨하게 할수록 빨라지고 잃을 수 있다 — 잴 것: 메시징 실험의 `acks=all`과 `acks=1`의 처리량 | quorum queue는 Raft 복제를 거치고, publisher confirm과 수동 ack를 켜야 잃지 않는다 — 잴 것: 메시징 실험의 그 설정과 자동 ack의 처리량 | 한 Redis가 쓰기를 모두 받고, fsync를 강하게 할수록 대가가 크다 — 잴 것: 메시징 실험의 `appendfsync` 설정별 처리량 | core는 저장하지 않는다. JetStream은 저장 방식(파일, 메모리)과 복제 수에 따라 달라진다 — 잴 것: 메시징 실험의 core와 JetStream(복제 1, 3)의 처리량 | SQS FIFO 큐는 초당 호출 수에 한도가 있고 모드에 따라 다르다(제품의 한도). 망을 왕복한다 — 잴 것: 메시징 실험의 집 서버에서 클라우드 큐까지의 보내기·받기 지연 |
| 메시지 크기 | `message.max.bytes` 기본 1048588바이트(레코드 배치의 한도, 바꿀 수 있다 — [브로커 설정](https://kafka.apache.org/44/configuration/broker-configs/)) | `max_message_size` 기본 16777216바이트, 최대 536870912바이트([Configuration](https://www.rabbitmq.com/docs/configure)). quorum queue는 큰 메시지에서 디스크를 많이 쓴다 | 메시지 하나의 한도는 문서에서 확인하지 못했다. 메시지가 클수록 메모리를 빨리 채운다 | `max_payload` 기본 1MB, 최대 64MB, 8MB를 넘는 값은 권하지 않는다([Configuration](https://docs.nats.io/running-a-nats-service/configuration)) | SQS 최대 1 MiB([메시지 한도](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html)), OCI Queue 최대 256 KB · 잴 것(다섯 방식 공통): 메시징 실험의 메시지 크기별 처리량 |
| 보관할 양 | 디스크에 둔다. 보관 기간이 길수록 디스크가 는다 — 잴 것: 메시징 실험의 보관량별 디스크 | 큐는 ack되면 지운다. 쌓이면 quorum queue의 메모리 색인이 는다 — 잴 것: 메시징 실험의 쌓였을 때의 메모리와 처리량. 오래 둘 것은 RabbitMQ stream이 메모리 부담이 적다 | 메모리 크기가 상한이다. 넘으면 잘라야 하고, 잘라 낸 것은 다시 읽지 못한다 — 잴 것: 메시징 실험의 메시지 수별 메모리 | JetStream은 정한 한도까지 둔다. 메모리 저장은 재시작하면 잃는다 | SQS 기본 4일, 최대 14일 · OCI Queue 기본 1일, 최대 7일(제품의 한도). 그보다 오래 둘 수 없다 |
| 받는 쪽의 수 | 그룹을 더하면 그룹마다 따로 읽고, 보관 중인 데이터를 그룹끼리 함께 쓴다 | fanout, topic exchange는 받는 쪽마다 큐를 하나씩 바인딩해 큐와 쌓인 메시지가 받는 쪽마다 생긴다. RabbitMQ stream은 받는 쪽이 몇이든 큐 하나에서 읽는다([Streams](https://www.rabbitmq.com/docs/streams)) — 잴 것: 메시징 실험의 받는 쪽 수별 처리량 | consumer group을 여럿 둔다 | core는 연결된 구독자 모두에게 간다. JetStream의 Interest 정책은 관심 있는 소비자가 모두 읽으면 지운다 | 받는 쪽마다 따로 받게 하려면 SNS 토픽에 받는 쪽마다 큐를 하나씩 구독시킨다([SNS → SQS](https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html)) — 잴 것: 메시징 실험의 받는 쪽 수별 사용료 |

## 아직 줄이 없는 것

위 어디에도 들지 않는 경우의 기본 방식은 메시징 실험 뒤에 정한다. 잃어도 되는 메시지(다음 값이 앞 값을 덮어 쓰는 것, 양이 많고 잃어도 되는 집계)는 Outbox를 거치는지부터 `communication-reliability.md`가 등급을 정할 때 정한다. core NATS를 줄로 둘지는 그 뒤에 본다. Kafka share group을 쓸 때 파티션 안의 순서가 지켜지는지, NATS JetStream이 같은 주제(subject) 안의 순서를 지키는지는 확인하지 않았다. 만나면 ROUTING.md의 절차로 정한다.
