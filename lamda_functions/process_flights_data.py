import boto3, csv, uuid

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    dynamo = boto3.resource('dynamodb')
    table = dynamo.Table('FlightsData')  # Dynamo table name (match Terraform)

    # S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    resp = s3.get_object(Bucket=bucket, Key=key)
    body = resp['Body'].read().decode('utf-8').splitlines()
    reader = csv.DictReader(body)

    total_flights = 0
    total_delay = 0.0

    for row in reader:
        total_flights += 1
        # adjust column name to your CSV (e.g., 'DEP_DELAY' or 'DEPARTURE_DELAY')
        delay = float(row.get('DEPARTURE_DELAY', 0) or 0)
        total_delay += delay

    avg_delay = (total_delay / total_flights) if total_flights else 0.0

    item = {
        'id': str(uuid.uuid4()),
        'total_flights': total_flights,
        'average_delay': avg_delay
    }

    table.put_item(Item=item)
    return {"status": "ok", "processed": total_flights}

