import json
from typing import Dict, Any
from dataclasses import dataclass
from models import Storyline, ActionType, GaugeState
import uuid

# MARK: - Erreurs personnalisées

@dataclass
class StorylineParseError(Exception):
    """Erreur de base pour le parsing des storylines"""
    message: str

    @classmethod
    def invalid_json(cls) -> 'StorylineParseError':
        return cls("Le JSON est invalide ou ne peut pas être décodé.")
    
    @classmethod
    def missing_key(cls, key: str) -> 'StorylineParseError':
        return cls(f"Clé manquante ou valeur nulle pour la clé : {key}.")
    
    @classmethod
    def invalid_type(cls, key: str) -> 'StorylineParseError':
        return cls(f"Type invalide pour la clé : {key}.")
    
    @classmethod
    def empty_steps(cls) -> 'StorylineParseError':
        return cls("Aucune étape trouvée dans la storyline.")
    
    @classmethod
    def empty_choices_in_step(cls, index: int) -> 'StorylineParseError':
        return cls(f"L'étape {index + 1} ne contient aucun choix.")

# MARK: - Parseur principal

def parse_storyline(json_string: str):
    print("[StorylineParser] Tentative de décodage du JSON:")
    print(json_string)
    
    try:
        data = json.loads(json_string)
        
        print(f"[StorylineParser] ID d'origine dans le JSON: {data.get('id')}")
        # Vérification et génération de l'UUID
        if 'id' not in data:
            print("[StorylineParser] Aucun ID trouvé, génération d'un nouvel UUID")
            data['id'] = str(uuid.uuid4())
        else:
            try:
                uuid_obj = uuid.UUID(data['id'])
                data['id'] = str(uuid_obj)
                print(f"[StorylineParser] UUID valide trouvé et normalisé: {data['id']}")
            except ValueError:
                print(f"[StorylineParser] ID invalide trouvé: {data['id']}, génération d'un nouvel UUID")
                data['id'] = str(uuid.uuid4())
        print(f"[StorylineParser] ID final utilisé: {data['id']}")
        
        corrected_json = json.dumps(data, ensure_ascii=False, indent=2)
        return Storyline(
            id=data['id'],
            title=data['title'],
            action_type=data['action_type'],
            steps=data['steps'],
            raw_json=corrected_json
        ), corrected_json
    except Exception as e:
        raise StorylineParseError(f"Erreur lors du parsing de la storyline : {str(e)}")
