"""
Prometheus Metrics
===================
Centralizes metric definitions so main.py and rag_chain.py stay focused
on business logic rather than instrumentation details.
"""

from prometheus_client import Counter, Histogram, generate_latest

REQUEST_COUNT = Counter(
    "rag_api_requests_total",
    "Total number of API requests",
    ["endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "rag_api_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
    buckets=(0.1, 0.5, 1, 2, 5, 10, 20, 30, 60),
)

INGEST_COUNT = Counter(
    "rag_api_documents_ingested_total",
    "Total number of documents ingested",
)


def generate_metrics() -> bytes:
    return generate_latest()
