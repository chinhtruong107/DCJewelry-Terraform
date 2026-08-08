import json
import os
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def lambda_handler(event, context):
    token = os.environ["TELEGRAM_BOT_TOKEN"]
    chat_id = os.environ["TELEGRAM_CHAT_ID"]

    for record in event.get("Records", []):
        sns = record["Sns"]
        text = format_notification(sns)
        body = urlencode({"chat_id": chat_id, "text": text}).encode("utf-8")
        request = Request(
            f"https://api.telegram.org/bot{token}/sendMessage",
            data=body,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        with urlopen(request, timeout=10) as response:
            response.read()

    return {"statusCode": 200}


def format_notification(sns):
    subject = sns.get("Subject") or "DCJewelry infrastructure alert"
    raw_message = sns.get("Message", "No alarm details were supplied.")

    try:
        alarm = json.loads(raw_message)
    except json.JSONDecodeError:
        return f"ℹ️ DCJewelry notification\n\n{subject}\n\n{raw_message}"[:4096]

    state = alarm.get("NewStateValue", "UNKNOWN")
    icon = {
        "ALARM": "🚨",
        "OK": "✅",
        "INSUFFICIENT_DATA": "⚠️",
    }.get(state, "ℹ️")
    alarm_name = alarm.get("AlarmName", subject)
    description = alarm.get("AlarmDescription", "")
    reason = alarm.get("NewStateReason", "No reason supplied.")
    region = alarm.get("Region", "Unknown region")
    changed_at = alarm.get("StateChangeTime", "Unknown time")

    lines = [
        f"{icon} DCJewelry | {state}",
        "",
        f"Alarm: {alarm_name}",
    ]
    if description:
        lines.append(f"Details: {description}")
    lines.extend(
        [
            f"Reason: {reason}",
            f"Region: {region}",
            f"Time: {changed_at}",
        ]
    )
    return "\n".join(lines)[:4096]
