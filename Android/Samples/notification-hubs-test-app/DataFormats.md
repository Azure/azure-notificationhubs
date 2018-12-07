# Simple notification

```
{"data":{"message":"Notification Hub test notification"}}
```

# Title
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"title": "Important notification"
	}
}
```

# Custom action
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"customAction": "snooze" // Possible values: "snooze", "dismiss"
	}
}
```

# Badge count
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"badgeCount": 10
	}
}
```

# Custom audio
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"customAudio": "alarm" // Possible values: "alarm", "notification", "ringtone"
	}
}
```

# Big picture
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"includePicture": true
	}
}
```

# Big text
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"messageSize": "large" // Possible values: "regular", "large"
	}
}
```

# Notification timeout
```
{
	"data":	{
		"message":"Notification Hub test notification", 
		"timeoutMs": 5000
	}
}
```