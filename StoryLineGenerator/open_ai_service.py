import os
import json
from typing import Callable, Dict, Any, Optional
import requests
from dataclasses import dataclass

@dataclass
class OpenAIResponse:
    content: str
    error: Optional[str] = None

class OpenAIService:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(OpenAIService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self._initialized = True
        self.api_url = "https://api.openai.com/v1/chat/completions"
        self.api_key = os.getenv("OPENAI_API_KEY", "YOUR_API_KEY")
        print(f"API Key: {self.api_key}")
    
    def generate_storyline(self, prompt: str, completion: Callable[[OpenAIResponse], None]) -> None:
        """
        Génère une storyline en utilisant l'API OpenAI.
        
        Args:
            prompt: Le prompt pour générer la storyline
            completion: Callback appelé avec la réponse ou l'erreur
        """
        messages = [
            {"role": "system", "content": "Tu es un créateur d'histoires pour Tibouchi. Réponds uniquement avec le JSON de la storyline, sans aucun autre texte."},
            {"role": "user", "content": prompt}
        ]
        
        payload = {
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.8
        }
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(
                self.api_url,
                headers=headers,
                json=payload
            )
            
            if not response.ok:
                completion(OpenAIResponse(
                    content="",
                    error=f"Erreur HTTP: {response.status_code}"
                ))
                return
            
            json_response = response.json()
            
            if "choices" in json_response and len(json_response["choices"]) > 0:
                message = json_response["choices"][0]["message"]
                if "content" in message:
                    completion(OpenAIResponse(content=message["content"]))
                    return
            
            completion(OpenAIResponse(
                content="",
                error="Format de réponse invalide"
            ))
            
        except requests.RequestException as e:
            completion(OpenAIResponse(
                content="",
                error=str(e)
            ))
        except json.JSONDecodeError as e:
            completion(OpenAIResponse(
                content="",
                error=f"Erreur de décodage JSON: {str(e)}"
            ))
        except Exception as e:
            completion(OpenAIResponse(
                content="",
                error=f"Erreur inattendue: {str(e)}"
            ))
