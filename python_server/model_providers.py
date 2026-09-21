from abc import ABC, abstractmethod
from langchain_openai import OpenAI
from key import OpenApikey  # Your existing key file
import requests
import anthropic

# Abstract base class for all models
class ModelProvider(ABC):
    @abstractmethod
    def generate(self, prompt: str) -> str:
        pass

# OpenAI/GPT Implementation
class OpenAIProvider(ModelProvider):
    def __init__(self, model_name: str = "gpt-3.5-turbo-instruct", api_key: str = None):
        self.model_name = model_name
        self.api_key = api_key or OpenApikey
        self.client = OpenAI(
            model_name=self.model_name,
            openai_api_key=self.api_key,
            temperature=1
        )
    
    def generate(self, prompt: str) -> str:
        # langchain's invoke() returns an AIMessage object, extract content
        result = self.client.invoke(prompt)
        # Handle both string and AIMessage types
        if hasattr(result, 'content'):
            return result.content
        elif isinstance(result, str):
            return result
        else:
            return str(result)

# Grok Implementation (using xAI API)
class GrokProvider(ModelProvider):
    def __init__(self, api_key: str):
        self.api_key = api_key
        # Note: You'll need to install xai-python or use HTTP requests
        # This is a placeholder structure
        import requests
        self.base_url = "https://api.x.ai/v1/chat/completions"
    
    def generate(self, prompt: str) -> str:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "grok-beta",
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 1
        }
        response = requests.post(self.base_url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

# Claude Implementation (Anthropic)
class ClaudeProvider(ModelProvider):
    def __init__(self, api_key: str, model_name: str = "claude-3-haiku-20240307"):
        self.api_key = api_key
        self.model_name = model_name
        self.client = anthropic.Anthropic(api_key=api_key)
    
    def generate(self, prompt: str) -> str:
        message = self.client.messages.create(
            model=self.model_name,
            max_tokens=1024,
            temperature=1,
            messages=[{"role": "user", "content": prompt}]
        )
        return message.content[0].text

# Model Factory
class ModelFactory:
    @staticmethod
    def create_provider(model_type: str, **kwargs) -> ModelProvider:
        model_type = model_type.lower()
        
        if model_type in ["gpt-3.5", "gpt-3.5-turbo", "gpt-4", "chatgpt", "openai"]:
            model_name = kwargs.get("model_name", "gpt-3.5-turbo-instruct")
            return OpenAIProvider(model_name=model_name)
        
        elif model_type in ["grok", "xai"]:
            api_key = kwargs.get("api_key")
            if not api_key:
                raise ValueError("Grok API key required")
            return GrokProvider(api_key=api_key)
        
        elif model_type in ["claude", "anthropic"]:
            api_key = kwargs.get("api_key")
            if not api_key:
                raise ValueError("Claude API key required")
            model_name = kwargs.get("model_name", "claude-3-haiku-20240307")
            return ClaudeProvider(api_key=api_key, model_name=model_name)
        
        else:
            # Default to OpenAI
            return OpenAIProvider()