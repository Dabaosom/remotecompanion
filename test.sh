curl -v -X POST http://192.168.1.2:8080/api/config \
     -H "Content-Type: application/json" \
     -d '{"masterEnabled": true, "nfcEnabled": true, "webUIEnabled": false, "triggers": {}, "favoriteTriggers": []}'
