#!/usr/bin/env python3

import os

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

import coding_ai


app = FastAPI(
    title="Coding AI",
    description="Local LLM + Aiven OpenSearch RAG",
    version="1.0.0"
)


class ChatRequest(BaseModel):
    question: str


@app.get("/")
def home():
    return {
        "name": "Coding AI",
        "status": "online",
        "brain": "local LLM",
        "knowledge": "Aiven OpenSearch",
        "cloud_ai": False
    }


@app.get("/health")
def health():

    aiven_ok = coding_ai.test_aiven()

    index_ok = False

    if aiven_ok:
        index_ok = coding_ai.index_exists()

    return {
        "status": "ok" if aiven_ok and index_ok else "degraded",
        "aiven": aiven_ok,
        "index": index_ok,
        "index_name": coding_ai.INDEX_NAME
    }


@app.get("/stats")
def stats():

    count = coding_ai.get_stats()

    if count is None:
        raise HTTPException(
            status_code=503,
            detail="Unable to retrieve Aiven statistics."
        )

    return {
        "knowledge_documents": count,
        "index": coding_ai.INDEX_NAME
    }


@app.post("/chat")
def chat(request: ChatRequest):

    question = request.question.strip()

    if not question:
        raise HTTPException(
            status_code=400,
            detail="Question cannot be empty."
        )

    results = coding_ai.search_knowledge(question)

    context = coding_ai.build_context(results)

    answer, error = coding_ai.local_llm_chat(
        question,
        context
    )

    if error:
        raise HTTPException(
            status_code=503,
            detail=error
        )

    return {
        "answer": answer,
        "knowledge_items": len(results)
    }