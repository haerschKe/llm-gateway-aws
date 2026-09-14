import json
import subprocess
import sys
from collections import defaultdict

FLOCI_ENDPOINT = "http://localhost:4566"

try:
    result = subprocess.run(
        [
            "aws", "dynamodb", "scan",
            "--table-name", "llm-gateway-requests",
            "--endpoint-url", FLOCI_ENDPOINT,
            "--region", "us-east-1",
        ],
        capture_output=True, text=True, check=True,
        env={
            "AWS_ACCESS_KEY_ID": "test",
            "AWS_SECRET_ACCESS_KEY": "test",
            "PATH": __import__("os").environ.get("PATH", ""),
        },
    )
except subprocess.CalledProcessError as e:
    print(f"aws dynamodb scan failed (exit {e.returncode}):", file=sys.stderr)
    print(e.stderr, file=sys.stderr)
    sys.exit(1)

items = json.loads(result.stdout)["Items"]

cost_by_key = defaultdict(float)
requests_by_key = defaultdict(int)

for item in items:
    api_key = item["apiKey"]["S"]
    cost = float(item["estimatedCostUsd"]["S"])
    cost_by_key[api_key] += cost
    requests_by_key[api_key] += 1

labels = list(cost_by_key.keys())
costs = [round(cost_by_key[k], 6) for k in labels]
counts = [requests_by_key[k] for k in labels]

html = f"""<!DOCTYPE html>
<html>
<head>
  <title>LLM Gateway - Cost Dashboard</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
</head>
<body>
  <h1>Estimated Cost by API Key</h1>
  <canvas id="costChart" width="600" height="300"></canvas>
  <script>
    new Chart(document.getElementById('costChart'), {{
      type: 'bar',
      data: {{
        labels: {json.dumps(labels)},
        datasets: [{{
          label: 'Estimated cost (USD)',
          data: {json.dumps(costs)},
        }}, {{
          label: 'Request count',
          data: {json.dumps(counts)},
          yAxisID: 'y1',
        }}]
      }},
      options: {{
        scales: {{
          y1: {{ position: 'right', grid: {{ drawOnChartArea: false }} }}
        }}
      }}
    }});
  </script>
</body>
</html>
"""

with open("dashboard.html", "w") as f:
    f.write(html)

print("Wrote dashboard.html - open it in a browser")