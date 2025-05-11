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
import argparse
import re
from datetime import datetime

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
    
    async def generate_storyline(self, action_type: ActionType, num_steps: int = 2, theme: Optional[str] = None) -> Storyline:
        """
        Génère une storyline pour un type d'action donné.
        
        Args:
            action_type: Le type d'action pour lequel générer la storyline
            num_steps: Le nombre d'étapes dans la storyline (par défaut: 2)
            theme: Un thème optionnel pour guider la génération de l'histoire
            
        Returns:
            La storyline générée
            
        Raises:
            Exception: Si la génération échoue après 10 tentatives
        """
        
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
        2. La storyline doit contenir exactement {num_steps} étapes, chacune avec exactement 2 choix
        3. Les conséquences doivent être logiques et proportionnelles aux choix : un choix risqué doit avoir des impacts plus importants qu'un choix prudent
        4. L'histoire doit être adaptée au type d'action demandé
        5. Les choix doivent avoir un impact significatif sur les jauges
        6. L'histoire doit être engageante et amusante
        7. IMPORTANT : Utilise "action_type" et non "actionType" dans le JSON
        8. IMPORTANT : Ne mets pas de balises markdown ou de commentaires dans le JSON
        9. IMPORTANT : Réponds UNIQUEMENT avec le JSON, sans aucun autre texte
        {f'10. IMPORTANT : L\'histoire doit être centrée sur le thème suivant : {theme}' if theme else ''}

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
    parser = argparse.ArgumentParser(description='Génère une storyline pour Tibouchi')
    parser.add_argument('--steps', type=int, default=2, help='Nombre d\'étapes dans la storyline (défaut: 2)')
    parser.add_argument('--theme', type=str, help='Thème optionnel pour la storyline')
    args = parser.parse_args()

    generator = StorylineGenerator()
    try:
        storyline = await generator.generate_storyline(ActionType.NOURRIR, num_steps=args.steps, theme=args.theme)
        print(f"Storyline générée avec succès :")
        print(f"Titre : {storyline.title}")
        print(f"Type d'action : {storyline.action_type.value}")
        print(f"Nombre d'étapes : {len(storyline.steps)}")
        if args.theme:
            print(f"Thème : {args.theme}")
        # Sauvegarde du JSON original dans un fichier (formaté)
        try:
            # Utiliser le JSON original stocké dans l'objet Storyline
            json_data = json.loads(storyline.raw_json if storyline.raw_json else json.dumps(storyline.__dict__, default=str))
            # Créer le dossier outputs s'il n'existe pas
            os.makedirs('outputs', exist_ok=True)
            # Nettoyer le titre pour le nom de fichier
            title = json_data.get('title', 'storyline')
            safe_title = re.sub(r'[^\w\-]', '_', title).strip('_')
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"outputs/{safe_title}_{timestamp}.json"
            with open(filename, "w", encoding="utf-8") as f:
                json.dump(json_data, f, ensure_ascii=False, indent=2)
            print(f"Storyline sauvegardée dans {filename} (formaté)")
        except Exception as e:
            print(f"Erreur lors de la sauvegarde du JSON : {e}")
    except Exception as e:
        print(f"Erreur lors de la génération : {str(e)}")

if __name__ == "__main__":
    asyncio.run(main())
