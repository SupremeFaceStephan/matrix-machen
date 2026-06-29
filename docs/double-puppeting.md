# Double puppeting
(one of the method, maybe other is better but this works)

1. Get access token
```bash
curl -XPOST -d '{"type":"m.login.password","identifier":{"type": "m.id.user", "user": "yourusername"},"password":"wordpass","initial_device_display_name":"mautrix-meta"}' https://matrix.domain.com/_matrix/client/v3/login
```
Change user, password, display-name and domain!

In response you get access token, copy it

2. Go to bridge bot
3. use command `login-matrix` and paste `access token`
