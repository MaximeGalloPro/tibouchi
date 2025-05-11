from dataclasses import dataclass
from typing import List, Optional, Union
from enum import Enum
from uuid import UUID

# MARK: - Core Enums

class ActionType(str, Enum):
    NOURRIR = "nourrir"
    ABREUVER = "abreuver"
    AVENTURE = "aventure"
    AMOUR = "amour"

class GaugeType(str, Enum):
    FAIM = "faim"
    SOIF = "soif"
    MENTAL = "mental"

class CharacterType(str, Enum):
    TIBOUCHI = "tibouchi"
    TIBIZOU = "tibizou"
    PTIBOU = "ptibou"

class Outcome:
    def __init__(self, outcome_type: str, reason: Optional[str] = None):
        self.outcome_type = outcome_type
        self.reason = reason

    @classmethod
    def survive(cls):
        return cls("survive")

    @classmethod
    def die(cls, reason: str):
        return cls("die", reason)

    @classmethod
    def return_home(cls):
        return cls("returnHome")

    @classmethod
    def next_step(cls):
        return cls("nextStep")

# MARK: - Core Gameplay Classes

@dataclass
class GaugeState:
    faim: int
    soif: int
    mental: int

@dataclass
class Trait:
    id: str
    name: str
    description: str

@dataclass
class Item:
    id: str
    name: str
    description: str
    protects_against: str

@dataclass
class CharacterState:
    type: CharacterType
    is_alive: bool
    gauges: GaugeState
    traits: List[Trait]
    inventory: List[Item]

# MARK: - Storyline Classes

@dataclass
class Choice:
    text: str
    consequence: str
    gauge_impact: GaugeState
    outcome: Outcome
    gain_trait: Optional[Trait] = None
    required_item: Optional[str] = None

    def __init__(self, text: str, consequence: str, gaugeImpact: dict, outcome: str, gainTrait: Optional[Trait] = None, requiredItem: Optional[str] = None):
        self.text = text
        self.consequence = consequence
        self.gauge_impact = GaugeState(**gaugeImpact)
        self.outcome = Outcome(outcome)
        self.gain_trait = gainTrait
        self.required_item = requiredItem

@dataclass
class StoryStep:
    prompt: str
    choices: List[Choice]

    def __init__(self, prompt: str = None, description: str = None, choices: List[dict] = None):
        self.prompt = prompt if prompt is not None else description
        self.choices = [Choice(**choice) for choice in (choices or [])]

@dataclass
class Storyline:
    id: UUID
    title: str
    action_type: ActionType
    steps: List[StoryStep]

    def __init__(self, id: str, title: str, action_type: Union[str, ActionType], steps: List[dict]):
        self.id = id
        self.title = title
        if isinstance(action_type, str):
            self.action_type = ActionType(action_type)
        else:
            self.action_type = action_type
        self.steps = [StoryStep(**step) for step in steps]

# MARK: - Game State

@dataclass
class GameState:
    characters: List[CharacterState]
    coins: int
    days_survived: int 