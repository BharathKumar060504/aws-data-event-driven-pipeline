import boto3, json
from datetime import date

def lambda_handler(event, context):
    dynamo = boto3.resource('dynamodb')
    table = dynamo.Table('FlightsData')
    s3 = boto3.client('s3')

    # scan table (for small demo datasets this is fine)
    resp = table.scan()
    items = resp.get('Items', [])

    total_flights = sum(int(i.get('total_flights', 0)) for i in items)
    avg_delay = (sum(float(i.get('average_delay', 0)) for i in items) / len(items)) if items else 0.0

    report = {
        "date": str(date.today()),
        "total_flights": total_flights,
        "average_delay": round(avg_delay, 2)
    }

    bucket = "flights-data-pipeline-bharath"  # match Terraform S3 bucket resource
    key = f"reports/daily_report_{date.today()}.json"

    s3.put_object(Bucket=bucket, Key=key, Body=json.dumps(report), ContentType='application/json')

    # optionally publish a small SNS notification (omitted here if Lambda lacks SNS perms)
    return {"status": "report_created", "report_key": key}

