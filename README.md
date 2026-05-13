# Projet Ligue 1 2025 - Base de données PostgreSQL

## 📌 Objectif

Mettre en place une base de données relationnelle PostgreSQL pour analyser les performances des joueurs et équipes de Ligue 1 sur la saison 2025.

Le projet permet de :

- structurer les données issues des fichiers CSV ;
- créer une base relationnelle propre ;
- charger automatiquement les données ;
- exécuter des requêtes SQL analytiques ;
- produire des indicateurs pour l’aide à la décision sportive ;
- préparer une recommandation de recrutement.

---

## 🧱 Stack technique

- PostgreSQL 16 via Docker
- Docker Compose
- DataGrip / IntelliJ / DBeaver / pgAdmin
- SQL
- Fichiers CSV

---

## 📂 Structure du projet

```txt
projet-ligue1/
├── docker-compose.yml
├── README.md
├── docker_commandes_ligue1.md
├── sql/
│   ├── init_database.sql
│   └── import_data.sql
└── data/
    ├── attendu.csv
    ├── equipe.csv
    ├── joueur.csv
    ├── performance.csv
    ├── position.csv
    ├── progression.csv
    ├── salaire_source.csv
    └── temps_de_jeu.csv
```

---

## 🔌 Connexion à PostgreSQL

| Paramètre        | Valeur            |
|------------------|-------------------|
| Host             | `localhost`       |
| Port             | `5432`            |
| Database         | `ligue1_2025`     |
| User             | `postgres`        |
| Password         | `postgres`        |
| Container Docker | `ligue1-postgres` |

---

## 🚀 Lancement du projet

Démarrer PostgreSQL avec Docker Compose :

```bash
docker compose up -d
```

Vérifier que le conteneur tourne :

```bash
docker ps
```

Consulter les logs PostgreSQL :

```bash
docker logs ligue1-postgres
```

---

## 🏗️ Création des tables

Le fichier `sql/init_database.sql` contient la création des tables, des clés primaires, des clés étrangères et des contraintes.

Exécuter le script :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/init_database.sql
```

---

## 📥 Import automatique des données CSV

Le fichier `sql/import_data.sql` permet d’importer automatiquement tous les fichiers CSV présents dans le dossier `data`.

Le dossier local `./data` est monté dans le conteneur PostgreSQL sous le chemin `/data`.

Le dossier local `./sql` est monté dans le conteneur PostgreSQL sous le chemin `/sql`.

Lancer l’import automatique :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/import_data.sql
```

Alternative depuis le fichier local :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/import_data.sql
```

---

## ⚠️ Ordre important des imports

L’ordre d’import est important à cause des clés étrangères.

Il faut importer les fichiers dans cet ordre :

1. `equipe.csv`
2. `position.csv`
3. `joueur.csv`
4. `temps_de_jeu.csv`
5. `performance.csv`
6. `attendu.csv`
7. `progression.csv`
8. `salaire_source.csv`

### Pourquoi cet ordre ?

- `equipe` et `position` sont des tables de référence.
- `joueur` dépend de `equipe` et `position`.
- `temps_de_jeu`, `performance`, `attendu` et `progression` dépendent de `joueur`.
- `salaire_source` peut être reliée à `joueur` après rapprochement.

---

## 🧾 Import manuel des données

Si l’import automatique ne fonctionne pas, les données peuvent être importées manuellement avec `COPY`.

Ouvrir PostgreSQL :

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025
```

Puis exécuter les commandes dans cet ordre :

```sql
COPY equipe(id_equipe, nom_equipe)
FROM '/data/equipe.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY position(code_position, libelle_position)
FROM '/data/position.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY joueur(id_joueur, nom_joueur, nation, annee_naissance, code_position, id_equipe)
FROM '/data/joueur.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY temps_de_jeu(id_joueur, matchs_joues, matchs_titulaires, minutes_jouees, matchs_90)
FROM '/data/temps_de_jeu.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY performance(
    id_joueur,
    buts,
    passes_decisives,
    buts_plus_passes,
    buts_hors_penalties,
    penalties_marques,
    penalties_tentes,
    cartons_jaunes,
    cartons_rouges
)
FROM '/data/performance.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY attendu(id_joueur, xg, npxg, xag, npxg_xag)
FROM '/data/attendu.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY progression(id_joueur, progression_conduite, progression_passe, progression_course)
FROM '/data/progression.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

COPY salaire_source(nom_joueur, age, salaire_annuel, note_source, id_joueur)
FROM '/data/salaire_source.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

---

## 🔄 Repartir de zéro

Pour supprimer la base existante et repartir proprement :

```bash
docker compose down -v
docker compose up -d
```

Puis recréer les tables :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/init_database.sql
```

Puis réimporter les données :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/import_data.sql
```

---

## 🧪 Vérifications après import

Lister les tables :

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "\dt"
```

Vérifier le nombre de joueurs :

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT COUNT(*) FROM joueur;"
```

Vérifier le nombre de lignes par table :

```sql
SELECT 'equipe' AS table_name, COUNT(*) AS nombre_lignes FROM equipe
UNION ALL
SELECT 'position', COUNT(*) FROM position
UNION ALL
SELECT 'joueur', COUNT(*) FROM joueur
UNION ALL
SELECT 'temps_de_jeu', COUNT(*) FROM temps_de_jeu
UNION ALL
SELECT 'performance', COUNT(*) FROM performance
UNION ALL
SELECT 'attendu', COUNT(*) FROM attendu
UNION ALL
SELECT 'progression', COUNT(*) FROM progression
UNION ALL
SELECT 'salaire_source', COUNT(*) FROM salaire_source;
```

Tester une jointure simple :

```sql
SELECT 
    j.nom_joueur,
    e.nom_equipe
FROM joueur j
JOIN equipe e ON j.id_equipe = e.id_equipe
LIMIT 10;
```

Tester une jointure analytique :

```sql
SELECT 
    j.nom_joueur,
    e.nom_equipe,
    p.buts
FROM joueur j
JOIN equipe e ON j.id_equipe = e.id_equipe
JOIN performance p ON j.id_joueur = p.id_joueur
ORDER BY p.buts DESC
LIMIT 10;
```

---

## 🧩 Modèle relationnel

Le modèle repose sur une table centrale `joueur`.

Relations principales :

- `equipe` 1 → N `joueur`
- `position` 1 → N `joueur`
- `joueur` 1 → 1 `temps_de_jeu`
- `joueur` 1 → 1 `performance`
- `joueur` 1 → 1 `attendu`
- `joueur` 1 → 1 `progression`
- `joueur` 0/1 → 0/1 `salaire_source`

Les tables statistiques sont en relation 1-1 avec `joueur`, car les données sont agrégées à l’échelle de la saison 2025 : une ligne par joueur et par table statistique.

---

## 🎯 Objectif final

- Base PostgreSQL fonctionnelle
- Données CSV chargées automatiquement
- Modèle relationnel cohérent
- Requêtes SQL analytiques prêtes
- Résultats exploitables pour le staff sportif
- Recommandation de recrutement basée sur les données
