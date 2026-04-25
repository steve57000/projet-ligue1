\set ON_ERROR_STOP on

-- ============================================================
-- IMPORT AUTOMATIQUE DES DONNÉES CSV
-- Projet : SportDataPulse - Ligue 1 2025
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
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY position(code_position, libelle_position)
    FROM '/data/position.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY joueur(
            id_joueur,
            code_position,
            id_equipe,
            nom_joueur,
            nation,
            annee_naissance
    )
    FROM '/data/joueur.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY temps_de_jeu(
                  id_joueur,
                  matchs_joues,
                  matchs_titulaires,
                  minutes_jouees,
                  matchs_90
    )
    FROM '/data/temps_de_jeu.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY performance(
                 id_joueur,
                 buts,
                 passes_decisives,
                 buts_hors_penalties,
                 penalties_marques,
                 penalties_tentes,
                 cartons_jaunes,
                 cartons_rouges
    )
    FROM '/data/performance.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY attendu(
             id_joueur,
             xg,
             npxg,
             xag
    )
    FROM '/data/attendu.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY progression(
                 id_joueur,
                 progression_conduite,
                 progression_passe,
                 progression_course
    )
    FROM '/data/progression.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY salaire_source(
                    id_source,
                    nom_joueur,
                    age,
                    salaire_annuel,
                    note_source
    )
    FROM '/data/salaire_source.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ';');

SELECT 'Import terminé avec succès' AS status;

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