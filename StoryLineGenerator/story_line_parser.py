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

def parse_storyline(json_data: str) -> Storyline:
    """
    Parse une storyline à partir d'une chaîne JSON.
    
    Args:
        json_data: La chaîne JSON contenant la storyline
        
    Returns:
        La storyline parsée
        
    Raises:
        StorylineParseError: Si le parsing échoue
    """
    print("[StorylineParser] Tentative de décodage du JSON:")
    print(json_data)
    
    try:
        # Décodage du JSON
        storyline_dict = json.loads(json_data)
        storyline = Storyline(**storyline_dict)
        print(f"[StorylineParser] Décodage réussi. Storyline: {storyline.title}")
        
        # Validation du titre
        if not storyline.title:
            print("[StorylineParser] Erreur: titre manquant.")
            raise StorylineParseError.missing_key("title")
        
        # Validation du type d'action
        allowed_actions = ["nourrir", "abreuver", "aventure", "amour"]
        if storyline.action_type.value not in allowed_actions:
            print(f"[StorylineParser] Erreur: actionType invalide: {storyline.action_type.value}")
            raise StorylineParseError.invalid_type("actionType")
        
        # Validation des étapes
        if not storyline.steps:
            print("[StorylineParser] Erreur: aucune étape trouvée.")
            raise StorylineParseError.empty_steps()
        
        # Validation de chaque étape et de ses choix
        for index, step in enumerate(storyline.steps):
            if not step.prompt:
                print(f"[StorylineParser] Erreur: prompt manquant à l'étape {index + 1}")
                raise StorylineParseError.missing_key(f"prompt in step {index + 1}")
            
            if not step.choices:
                print(f"[StorylineParser] Erreur: aucun choix à l'étape {index + 1}")
                raise StorylineParseError.empty_choices_in_step(index)
            
            for choice in step.choices:
                if not choice.text:
                    print(f"[StorylineParser] Erreur: texte du choix manquant à l'étape {index + 1}")
                    raise StorylineParseError.missing_key(f"text in choice (step {index + 1})")
                
                if not choice.consequence:
                    print(f"[StorylineParser] Erreur: conséquence du choix manquante à l'étape {index + 1}")
                    raise StorylineParseError.missing_key(f"consequence in choice (step {index + 1})")
                
                # Validation des valeurs de gaugeImpact
                gauge_impact = choice.gauge_impact
                if (gauge_impact.faim < -10 or gauge_impact.faim > 10 or
                    gauge_impact.soif < -10 or gauge_impact.soif > 10 or
                    gauge_impact.mental < -10 or gauge_impact.mental > 10):
                    print(f"[StorylineParser] Erreur: valeur de gaugeImpact hors limites à l'étape {index + 1}")
                    raise StorylineParseError.invalid_type(f"gaugeImpact values in choice (step {index + 1})")
        
        return storyline
        
    except json.JSONDecodeError as e:
        print(f"[StorylineParser] Décodage JSON échoué : {str(e)}")
        raise StorylineParseError.invalid_json()
    except Exception as e:
        print(f"[StorylineParser] Erreur inattendue : {str(e)}")
        raise StorylineParseError(f"Erreur inattendue : {str(e)}")
