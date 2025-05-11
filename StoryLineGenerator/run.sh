#!/bin/bash

# Crée l'environnement virtuel s'il n'existe pas
echo "[run.sh] Vérification de l'environnement virtuel..."
if [ ! -d "venv" ]; then
  echo "[run.sh] Création de l'environnement virtuel..."
  python3 -m venv venv
fi

# Active l'environnement virtuel
echo "[run.sh] Activation de l'environnement virtuel..."
source venv/bin/activate

# Installe les dépendances
echo "[run.sh] Installation des dépendances..."
pip install -r requirements.txt

# Exécute le script Python avec tous les arguments passés à run.sh
echo "[run.sh] Exécution du générateur de storyline..."
python story_line_generator.py "$@" 