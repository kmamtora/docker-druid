docker build -t karanmamtora/druid-custom .
docker run -d -p 3000:8082 -p 3001:8081 -p 3003:8090 karanmamtora/druid-custom
docker exec -it karanmamtora/druid-custom /bin/bash

test
