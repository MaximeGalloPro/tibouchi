import json
from typing import Dict, Any
from dataclasses import dataclass
from models import Storyline, ActionType, GaugeState

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

def parse_storyline(json_string: str) -> Storyline:
    """
    Parse une storyline à partir d'une chaîne JSON.
    
    Args:
        json_string: La chaîne JSON contenant la storyline
        
    Returns:
        La storyline parsée
        
    Raises:
        StorylineParseError: Si le parsing échoue
    """
    print("[StorylineParser] Tentative de décodage du JSON:")
    print(json_string)
    
    try:
        data = json.loads(json_string)
        return Storyline(
            id=data['id'],
            title=data['title'],
            action_type=data['action_type'],
            steps=data['steps'],
            raw_json=json_string
        )
    except Exception as e:
        raise StorylineParseError(f"Erreur lors du parsing de la storyline : {str(e)}")
