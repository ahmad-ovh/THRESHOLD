"""
Vercel Serverless Function entry point for THRESHOLD FastAPI backend.
"""
from src.main import app

# Vercel looks for `app` in index.py
__all__ = ["app"]
