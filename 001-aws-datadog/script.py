from datadog import initialize, api
import time, random

options = {
    'api_key': '<YOUR_API_KEY>',
    'api_host': 'https://datadoghq.eu',
}


initialize(**options)

response = api.Metric.send(
                            metric='mycustom.datadog.metric',
                            points=[(int(time.time()), random.randint(0,100))],
                            tags=["env:dev"],
                            type='rate'
                          )
