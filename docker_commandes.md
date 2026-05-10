# Commandes Docker utiles — Projet Ligue 1 PostgreSQL

Ce fichier regroupe les commandes utiles pour lancer, gérer, réinitialiser et vérifier la base PostgreSQL du projet Ligue 1 2025.

---

## 1) Lancer le projet

```bash
docker compose up -d
```

---

## 2) Vérifier que le conteneur tourne

```bash
docker ps
```

---

## 3) Voir les logs PostgreSQL

```bash
docker logs ligue1-postgres
```

---

## 4) Arrêter le projet

```bash
docker compose down
```

---

## 5) Arrêter le projet et supprimer le volume de données

⚠️ À utiliser seulement si tu veux repartir de zéro.

```bash
docker compose down -v
```

---

## 6) Redémarrer le projet

```bash
docker compose restart
```

---

## 7) Reconstruire / relancer après modification du docker-compose.yml

```bash
docker compose down
docker compose up -d
```

---

## 8) Se connecter au conteneur PostgreSQL

```bash
docker exec -it ligue1-postgres bash
```

---

## 9) Ouvrir PostgreSQL en ligne de commande

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025
```

---

## 10) Lister les bases

Dans `psql` :

```sql
\l
```

---

## 11) Se connecter à la base du projet

Dans `psql` :

```sql
\c ligue1_2025
```

---

## 12) Lister les tables

Dans `psql` :

```sql
\dt
```

---

## 13) Voir la structure d’une table

Dans `psql` :

```sql
\d joueur
```

Autres exemples :

```sql
\d performance
\d temps_de_jeu
\d salaire_source
```

---

## 14) Exécuter le fichier de création des tables

Depuis le terminal du projet :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/init_database.sql
```

---

## 15) Importer automatiquement tous les CSV

Le fichier `sql/import_data.sql` importe les données depuis le dossier `/data` du conteneur.

Commande recommandée :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/import_data.sql
```

Alternative :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/import_data.sql
```

---

## 16) Ordre important des imports manuels

L’ordre est important à cause des clés étrangères.

1. `equipe`
2. `position`
3. `joueur`
4. `temps_de_jeu`
5. `performance`
6. `attendu`
7. `progression`
8. `salaire_source`

---

## 17) Importer un CSV manuellement avec PostgreSQL

Exemple pour la table `equipe` :

```sql
COPY equipe(id_equipe, nom_equipe)
FROM '/data/equipe.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

Exemple pour la table `joueur` :

```sql
COPY joueur(id_joueur, nom_joueur, nation, annee_naissance, code_position, id_equipe)
FROM '/data/joueur.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

---

## 18) Copier un fichier CSV dans le conteneur

Normalement, ce n’est pas nécessaire si le dossier `./data` est bien monté dans `docker-compose.yml`.

Mais si besoin :

```bash
docker cp data/joueur.csv ligue1-postgres:/tmp/joueur.csv
```

Puis dans `psql` :

```sql
COPY joueur(id_joueur, nom_joueur, nation, annee_naissance, code_position, id_equipe)
FROM '/tmp/joueur.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');
```

---

## 19) Vérifier rapidement le contenu d’une table

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT * FROM joueur LIMIT 10;"
```

---

## 20) Vérifier le nombre de lignes d’une table

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT COUNT(*) FROM joueur;"
```

Autres exemples :

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT COUNT(*) FROM equipe;"
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT COUNT(*) FROM performance;"
```

---

## 21) Vérifier le nombre de lignes de toutes les tables

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT 'equipe' AS table_name, COUNT(*) FROM equipe UNION ALL SELECT 'position', COUNT(*) FROM position UNION ALL SELECT 'joueur', COUNT(*) FROM joueur UNION ALL SELECT 'temps_de_jeu', COUNT(*) FROM temps_de_jeu UNION ALL SELECT 'performance', COUNT(*) FROM performance UNION ALL SELECT 'attendu', COUNT(*) FROM attendu UNION ALL SELECT 'progression', COUNT(*) FROM progression UNION ALL SELECT 'salaire_source', COUNT(*) FROM salaire_source;"
```

---

## 22) Supprimer uniquement le conteneur

```bash
docker rm -f ligue1-postgres
```

---

## 23) Supprimer le volume de données

⚠️ Supprime toutes les données PostgreSQL du projet.

```bash
docker volume rm projet-ligue1_pgdata
```

Selon le nom réel du dossier projet, le volume peut avoir un autre nom.

Pour lister les volumes :

```bash
docker volume ls
```

---

# Commandes SQL utiles pour le projet

## Vérifier les tables créées

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

---

## Compter les lignes d’une table

```sql
SELECT COUNT(*) FROM joueur;
SELECT COUNT(*) FROM equipe;
SELECT COUNT(*) FROM performance;
SELECT COUNT(*) FROM temps_de_jeu;
SELECT COUNT(*) FROM attendu;
SELECT COUNT(*) FROM progression;
SELECT COUNT(*) FROM salaire_source;
```

---

## Tester une jointure simple

```sql
SELECT 
    j.nom_joueur,
    e.nom_equipe
FROM joueur j
JOIN equipe e ON j.id_equipe = e.id_equipe
LIMIT 10;
```

---

## Tester une jointure avec les performances

```sql
SELECT 
    j.nom_joueur,
    e.nom_equipe,
    p.buts,
    p.passes_decisives
FROM joueur j
JOIN equipe e ON j.id_equipe = e.id_equipe
JOIN performance p ON j.id_joueur = p.id_joueur
ORDER BY p.buts DESC
LIMIT 10;
```

---

## Vérifier les joueurs sans équipe liée

```sql
SELECT *
FROM joueur
WHERE id_equipe IS NULL;
```

---

## Vérifier les joueurs sans position liée

```sql
SELECT *
FROM joueur
WHERE code_position IS NULL;
```

---

## Vérifier les doublons potentiels sur les noms

```sql
SELECT 
    nom_joueur,
    COUNT(*) AS nombre_occurrences
FROM joueur
GROUP BY nom_joueur
HAVING COUNT(*) > 1
ORDER BY nombre_occurrences DESC;
```

---

## Vérifier les joueurs sans performance

```sql
SELECT j.*
FROM joueur j
LEFT JOIN performance p ON j.id_joueur = p.id_joueur
WHERE p.id_joueur IS NULL;
```

---

## Vérifier les joueurs sans temps de jeu

```sql
SELECT j.*
FROM joueur j
LEFT JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
WHERE t.id_joueur IS NULL;
```

---

## Vérifier le top 10 des buteurs

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

# Paramètres de connexion DataGrip / IntelliJ

| Paramètre | Valeur |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `ligue1_2025` |
| User | `postgres` |
| Password | `postgres` |

---

# Procédure conseillée

Pour repartir proprement :

```bash
docker compose down -v
docker compose up -d
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/init_database.sql
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/import_data.sql
```

Puis vérifier :

```bash
docker exec -it ligue1-postgres psql -U postgres -d ligue1_2025 -c "SELECT COUNT(*) FROM joueur;"
```

---

# Conseil pratique

Pour ce projet, utilise surtout :

1. `docker compose up -d`
2. `docker ps`
3. `docker logs ligue1-postgres`
4. `docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 < sql/init_database.sql`
5. `docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/import_data.sql`
6. `docker compose down`
7. `docker compose down -v` pour repartir proprement

# Ajouter les commandes d’exécution et d’export

Pour lancer tout le fichier :

```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/requetes_metier.sql
```

Pour exporter les résultats dans un fichier texte, pratique pour garder une preuve :
```bash
docker exec -i ligue1-postgres psql -U postgres -d ligue1_2025 -f /sql/requetes_metier.sql > resultats_requetes.txt
```
