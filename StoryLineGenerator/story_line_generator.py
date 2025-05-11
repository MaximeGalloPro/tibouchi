from dotenv import load_dotenv
load_dotenv()
import json
import os
import uuid
from typing import Optional
import asyncio
from models import ActionType, Storyline
from open_ai_service import OpenAIService, OpenAIResponse
from story_line_parser import parse_storyline, StorylineParseError

def extract_first_json(text: str) -> Optional[str]:
    """
    Extrait le premier JSON valide d'une chaîne de texte.
    
    Args:
        text: Le texte contenant potentiellement un JSON
        
    Returns:
        Le JSON extrait ou None si aucun JSON n'est trouvé
    """
    # Supprime les balises markdown éventuelles et espaces inutiles
    cleaned = text.replace("```json", "").replace("```", "").strip()
    
    # Cherche la première accolade ouvrante et la dernière fermante
    try:
        start = cleaned.index("{")
        end = cleaned.rindex("}")
        return cleaned[start:end + 1]
    except ValueError:
        return None

class StorylineGenerator:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(StorylineGenerator, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self._initialized = True
        self.open_ai_service = OpenAIService()
        # TODO: Implémenter StorylineStorage
        # self.storyline_storage = StorylineStorage()
    
    async def generate_storyline(self, action_type: ActionType) -> Storyline:
        """
        Génère une storyline pour un type d'action donné.
        
        Args:
            action_type: Le type d'action pour lequel générer la storyline
            
        Returns:
            La storyline générée
            
        Raises:
            Exception: Si la génération échoue après 10 tentatives
        """
        # Charger le prompt template
        try:
            prompt_template_path = os.path.join(os.path.dirname(__file__), "prompt_story_generation.txt")
            with open(prompt_template_path, "r", encoding="utf-8") as f:
                prompt_template = f.read()
        except Exception as e:
            raise Exception(f"Impossible de charger le template de prompt: {str(e)}")
        
        # Créer le prompt spécifique pour l'action
        prompt = f"""
        Tu es un créateur d'histoires pour le jeu Tibouchi. Tu dois créer une storyline interactive qui suit le format JSON suivant :

        {{
            "id": "uuid-généré",
            "title": "Titre de l'histoire",
            "action_type": "type d'action (nourrir, abreuver, aventure, amour)",
            "steps": [
                {{
                    "prompt": "Description de la situation",
                    "choices": [
                        {{
                            "text": "Option 1",
                            "consequence": "Conséquence de l'option 1",
                            "gaugeImpact": {{
                                "faim": 0,  // Entre -10 et 10
                                "soif": 0,  // Entre -10 et 10
                                "mental": 0 // Entre -10 et 10
                            }},
                            "outcome": "survive", // ou "die", "returnHome", "nextStep"
                            "gainTrait": null, // ou un trait si applicable
                            "requiredItem": null // ou l'ID d'un objet requis si applicable
                        }}
                    ]
                }}
            ]
        }}

        Règles importantes :
        1. Les valeurs de gaugeImpact doivent être entre -10 et 10
        2. Chaque étape doit avoir au moins 2 choix
        3. Les conséquences doivent être cohérentes avec les choix
        4. L'histoire doit être adaptée au type d'action demandé
        5. Les choix doivent avoir un impact significatif sur les jauges
        6. L'histoire doit être engageante et amusante
        7. IMPORTANT : Utilise "action_type" et non "actionType" dans le JSON
        8. IMPORTANT : Ne mets pas de balises markdown ou de commentaires dans le JSON
        9. IMPORTANT : Réponds UNIQUEMENT avec le JSON, sans aucun autre texte

        Génère une storyline pour l'action suivante : {action_type.value}
        """
        
        # Boucle de validation avec feedback
        max_attempts = 2
        attempt = 0
        last_error = None
        current_prompt = prompt
        
        while attempt < max_attempts:
            attempt += 1
            print(f"\nTentative {attempt}/{max_attempts}")
            print(f"Prompt envoyé à l'IA :\n{current_prompt}")
            
            # Créer un Future pour gérer la réponse asynchrone
            future = asyncio.Future()
            
            def handle_response(response: OpenAIResponse):
                if response.error:
                    future.set_exception(Exception(response.error))
                    return
                    
                try:
                    # Nettoyer la réponse pour extraire le JSON
                    cleaned_json_string = response.content.strip()
                    # Enlever les balises markdown et les commentaires
                    cleaned_json_string = cleaned_json_string.replace("```json", "").replace("```", "")
                    # Enlever les commentaires JSON (// ...)
                    cleaned_json_string = "\n".join(line.split("//")[0] for line in cleaned_json_string.split("\n"))
                    print(f"\nRéponse reçue de l'IA (nettoyée) :\n{cleaned_json_string}")
                    
                    # Ajouter l'ID UUID s'il n'est pas présent
                    json_data = json.loads(cleaned_json_string)
                    if "id" not in json_data:
                        json_data["id"] = str(uuid.uuid4())
                        cleaned_json_string = json.dumps(json_data)
                    
                    # Parser la storyline
                    storyline = parse_storyline(cleaned_json_string)
                    future.set_result(storyline)
                except json.JSONDecodeError as e:
                    future.set_exception(StorylineParseError.invalid_json())
                except StorylineParseError as e:
                    future.set_exception(e)
                except Exception as e:
                    future.set_exception(Exception(f"Erreur inattendue : {str(e)}"))
            
            # Générer la storyline via OpenAI
            self.open_ai_service.generate_storyline(current_prompt, handle_response)
            
            try:
                # Attendre la réponse
                storyline = await future
                return storyline
            except Exception as e:
                last_error = e
                print(f"\nErreur lors de la génération : {str(e)}")
                # Ajouter le feedback à l'API pour la prochaine tentative
                current_prompt = f"""
                {prompt}
                
                Erreur précédente : {str(e)}
                
                IMPORTANT : 
                - Réponds UNIQUEMENT avec le JSON de la storyline
                - Ne mets aucun autre texte avant ou après le JSON
                - Assure-toi que le JSON est valide et suit exactement le format demandé
                - Utilise "action_type" et non "actionType"
                - Ne mets pas de balises markdown ou de commentaires dans le JSON
                - Corrige les erreurs mentionnées ci-dessus
                """
        
        # Si on arrive ici, toutes les tentatives ont échoué
        raise Exception(f"Échec de la génération après {max_attempts} tentatives. Dernière erreur : {str(last_error)}")

# Exemple d'utilisation
async def main():
    generator = StorylineGenerator()
    try:
        storyline = await generator.generate_storyline(ActionType.NOURRIR)
        print(f"Storyline générée avec succès :")
        print(f"Titre : {storyline.title}")
        print(f"Type d'action : {storyline.action_type.value}")
        print(f"Nombre d'étapes : {len(storyline.steps)}")
    except Exception as e:
        print(f"Erreur lors de la génération : {str(e)}")

if __name__ == "__main__":
    asyncio.run(main())
