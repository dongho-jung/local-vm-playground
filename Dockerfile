FROM alpine:3.21.3

ARG TARGETPLATFORM
ARG VM_VERSION=v1.113.0
ARG VM_PORT=8428
ARG SYNC_SLEEP_SEC=3

WORKDIR app

RUN wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$VM_VERSION/victoria-metrics-$(echo "$TARGETPLATFORM" | tr '/' '-')-$VM_VERSION.tar.gz
RUN tar xzf victoria-metrics-$(echo "$TARGETPLATFORM" | tr '/' '-')-$VM_VERSION.tar.gz

RUN apk add curl

COPY ./data_*.csv .

RUN ./victoria-metrics-prod -retentionPeriod=100y -inmemoryDataFlushInterval=3s& \
  until nc -z localhost $VM_PORT; do echo "Waiting for VictoriaMetrics..."; sleep 1; done \
  && VM_URL="http://localhost:$VM_PORT/api/v1/import/csv?format=1:time:rfc3339" \
  && curl "$VM_URL,2:label:job,3:label:fruit_name,4:label:fruit_color,5:label:fruit_size,6:metric:fruit_sold_count" -T data_fruit_sold_count.csv \
  && curl "$VM_URL,2:label:job,3:label:student_name,4:label:fruit_name,5:metric:student_has_fruit_allergy" -T data_student_has_fruit_allergy.csv \
  && curl "$VM_URL,2:label:job,3:label:student_name,4:label:fruit_name,5:metric:student_favorite_fruit_score" -T data_student_favorite_fruit_score.csv \
  && curl "$VM_URL,2:label:job,3:label:child_name,4:label:name,5:label:gender,6:label:phone,7:label:age,8:label:email,9:metric:parent_info" -T data_parent_info.csv \
  && curl "http://localhost:$VM_PORT/internal/force_flush" \
  && sleep $SYNC_SLEEP_SEC \
  && sync \
  && sleep $SYNC_SLEEP_SEC \
  && pkill -TERM victoria-metrics-prod

EXPOSE $VM_PORT

ENTRYPOINT ["./victoria-metrics-prod"]
CMD ["-retentionPeriod=100y"]
