\set ON_ERROR_STOP on

-- ============================================================
-- IMPORT AUTOMATIQUE DES DONNÉES CSV
-- Projet : SportDataPulse - Ligue 1 2025
-- Données brutes sans nettoyage
-- Séparateur CSV utilisé : point-virgule ;
-- ============================================================

TRUNCATE TABLE
    salaire_source,
    progression,
    attendu,
    performance,
    temps_de_jeu,
    joueur,
    position,
    equipe
    RESTART IDENTITY CASCADE;

COPY equipe(id_equipe, nom_equipe)
    FROM '/data/equipe.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

COPY position(code_position, libelle_position)
    FROM '/data/position.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

COPY joueur(
            id_joueur,
            code_position,
            id_equipe,
            nom_joueur,
            nation,
            annee_naissance
    )
    FROM '/data/joueur.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

-- Pour éviter de modifier les CSV,
-- on charge les colonnes décimales en TEXT,
-- puis convertir avec REPLACE(',', '.').

DROP TABLE IF EXISTS tmp_temps_de_jeu;
CREATE TEMP TABLE tmp_temps_de_jeu (
    id_joueur TEXT,
    matchs_joues TEXT,
    matchs_titulaires TEXT,
    minutes_jouees TEXT,
    matchs_90 TEXT
);

COPY tmp_temps_de_jeu(
    id_joueur,
    matchs_joues,
    matchs_titulaires,
    minutes_jouees,
    matchs_90
    )
    FROM '/data/temps_de_jeu.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

INSERT INTO temps_de_jeu(
    id_joueur,
    matchs_joues,
    matchs_titulaires,
    minutes_jouees,
    matchs_90
)
SELECT
    id_joueur::INT,
    matchs_joues::INT,
    matchs_titulaires::INT,
    minutes_jouees::INT,
    REPLACE(matchs_90, ',', '.')::NUMERIC(6,2)
FROM tmp_temps_de_jeu;

DROP TABLE IF EXISTS tmp_temps_de_jeu;


DROP TABLE IF EXISTS tmp_performance;

CREATE TEMP TABLE tmp_performance (
                                      id_joueur TEXT,
                                      buts TEXT,
                                      passes_decisives TEXT,
                                      buts_plus_passes TEXT,
                                      buts_hors_penalties TEXT,
                                      penalties_marques TEXT,
                                      penalties_tentes TEXT,
                                      cartons_jaunes TEXT,
                                      cartons_rouges TEXT,
                                      id_equipe TEXT,
                                      nom_equipe TEXT
);

COPY tmp_performance(
                     id_joueur,
                     buts,
                     passes_decisives,
                     buts_plus_passes,
                     buts_hors_penalties,
                     penalties_marques,
                     penalties_tentes,
                     cartons_jaunes,
                     cartons_rouges,
                     id_equipe,
                     nom_equipe
    )
    FROM '/data/performance.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

INSERT INTO performance(
    id_joueur,
    buts,
    passes_decisives,
    buts_hors_penalties,
    penalties_marques,
    penalties_tentes,
    cartons_jaunes,
    cartons_rouges
)
SELECT
    TRIM(id_joueur)::INT,
    TRIM(buts)::INT,
    TRIM(passes_decisives)::INT,
    TRIM(buts_hors_penalties)::INT,
    TRIM(penalties_marques)::INT,
    TRIM(penalties_tentes)::INT,
    TRIM(cartons_jaunes)::INT,
    TRIM(cartons_rouges)::INT
FROM tmp_performance;

DROP TABLE IF EXISTS tmp_performance;

DROP TABLE IF EXISTS tmp_attendu;

CREATE TEMP TABLE tmp_attendu (
    id_joueur TEXT,
    xg TEXT,
    npxg TEXT,
    xag TEXT,
    npxg_xag TEXT
);

COPY tmp_attendu(
    id_joueur,
    xg,
    npxg,
    xag,
    npxg_xag
)
FROM '/data/attendu.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

INSERT INTO attendu(
    id_joueur,
    xg,
    npxg,
    xag
)
SELECT
    id_joueur::INT,
    REPLACE(xg, ',', '.')::NUMERIC(6,2),
    REPLACE(npxg, ',', '.')::NUMERIC(6,2),
    REPLACE(xag, ',', '.')::NUMERIC(6,2)
FROM tmp_attendu;

DROP TABLE IF EXISTS tmp_attendu;


COPY progression(
    id_joueur,
    progression_conduite,
    progression_passe,
    progression_course
    )
    FROM '/data/progression.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

COPY salaire_source(
    id_joueur_source,
    nom_joueur,
    age,
    salaire_annuel,
    note_source
)
FROM '/data/salaire_source.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

-- ============================================================
-- Rapprochement automatique des salaires
-- Les id_joueur_source sont des identifiants propres à la source salaire.
-- Ils ne correspondent pas forcément aux id_joueur de la table joueur.
-- On rapproche donc d'abord par nom + âge, puis par nom seul.
-- ============================================================

UPDATE salaire_source s
SET id_joueur = j.id_joueur
FROM joueur j
WHERE s.id_joueur IS NULL
  AND LOWER(TRIM(s.nom_joueur)) = LOWER(TRIM(j.nom_joueur))
  AND s.age = 2025 - j.annee_naissance;

UPDATE salaire_source s
SET id_joueur = j.id_joueur
FROM joueur j
WHERE s.id_joueur IS NULL
  AND LOWER(TRIM(s.nom_joueur)) = LOWER(TRIM(j.nom_joueur));

-- ============================================================
-- Contrôle des salaires non rattachés
-- ============================================================

SELECT
    COUNT(*) AS total_salaires,
    COUNT(id_joueur) AS salaires_rattaches,
    COUNT(*) - COUNT(id_joueur) AS salaires_non_rattaches
FROM salaire_source;

SELECT
    id_joueur_source,
    nom_joueur,
    age,
    salaire_annuel,
    note_source,
    id_joueur
FROM salaire_source
WHERE id_joueur IS NULL
ORDER BY nom_joueur;