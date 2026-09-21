import os
import json
import urllib.request
import urllib.error
from typing import Optional


class CodingAI:
    """
    Local Coding AI client.

    Uses a local/OpenAI-compatible model server when available.
    No Gemini or OpenAI API key is required.
    """

    def __init__(
        self,
        model_url: Optional[str] = None,
        model: Optional[str] = None,
    ):
        self.model_url = (
            model_url
            or os.getenv("MODEL_URL")
            or os.getenv("LLAMA_URL")
            or "http://127.0.0.1:8080/v1/chat/completions"
        )

        self.model = (
            model
            or os.getenv("MODEL_NAME")
            or "qwen2.5-coder"
        )

    def ask(
        self,
        prompt: str,
        system: str = (
            "You are Coding AI, a practical programming assistant. "
            "Give accurate, working code and explain important errors briefly."
        ),
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> str:

        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": system,
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False,
        }

        data = json.dumps(payload).encode("utf-8")

        request = urllib.request.Request(
            self.model_url,
            data=data,
            headers={
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=300) as response:
                result = json.loads(response.read().decode("utf-8"))

            choices = result.get("choices", [])

            if choices:
                message = choices[0].get("message", {})
                content = message.get("content")

                if content:
                    return str(content)

            return json.dumps(result, indent=2)

        except urllib.error.HTTPError as e:
            try:
                error_body = e.read().decode("utf-8")
            except Exception:
                error_body = ""

            return f"Model server HTTP error {e.code}: {error_body}"

        except urllib.error.URLError as e:
            return (
                "Model server is unavailable. "
                f"URL: {self.model_url}. Error: {e}"
            )

        except Exception as e:
            return f"Coding AI error: {e}"


# Convenient default instance
coding_ai = CodingAI()


def ask_coding_ai(prompt: str) -> str:
    """Simple helper used by api.py."""
    return coding_ai.ask(prompt)


if __name__ == "__main__":
    print("Coding AI module loaded.")
    print(f"Model endpoint: {coding_ai.model_url}")
    print(f"Model: {coding_ai.model}")