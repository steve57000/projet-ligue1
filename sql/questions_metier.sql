-- Contrôle du nombre d'enregistrements dans les tables principales

SELECT 'Joueurs' AS table_controlee, COUNT(*) AS total_lignes
FROM joueur

UNION ALL

SELECT 'Équipes' AS table_controlee, COUNT(*) AS total_lignes
FROM equipe

UNION ALL

SELECT 'Performances' AS table_controlee, COUNT(*) AS total_lignes
FROM performance

UNION ALL

SELECT 'Temps de jeu' AS table_controlee, COUNT(*) AS total_lignes
FROM temps_de_jeu

UNION ALL

SELECT 'Attendu' AS table_controlee, COUNT(*) AS total_lignes
FROM attendu

UNION ALL

SELECT 'Progression' AS table_controlee, COUNT(*) AS total_lignes
FROM progression

ORDER BY table_controlee;


-- 1. Nombre total de buts marqués par équipe
SELECT
    e.nom_equipe,
    SUM(p.buts) AS total_buts
FROM equipe e
         JOIN joueur j ON e.id_equipe = j.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
GROUP BY e.nom_equipe
ORDER BY total_buts DESC;


-- 2. Nombre de matchs joués en moyenne par joueur en L1, par equipe
SELECT
    e.nom_equipe AS equipe,
    ROUND(AVG(t.matchs_joues), 2) AS moyenne_matchs_joues_par_joueur
FROM temps_de_jeu t
         JOIN joueur j
              ON t.id_joueur = j.id_joueur
         JOIN equipe e
              ON j.id_equipe = e.id_equipe
GROUP BY e.nom_equipe
ORDER BY moyenne_matchs_joues_par_joueur DESC;

-- 3. Nombre de postes et % du total général pour chaque poste
SELECT
    pos.code_position,
    pos.libelle_position,
    COUNT(j.id_joueur) AS nombre_joueurs,
    ROUND(
            COUNT(j.id_joueur) * 100.0
                / SUM(COUNT(j.id_joueur)) OVER (),
            2
    ) AS pourcentage_total
FROM position pos
         JOIN joueur j
              ON pos.code_position = j.code_position
GROUP BY pos.code_position, pos.libelle_position
ORDER BY nombre_joueurs DESC;

-- 4. Nombre moyen de buts marqués par un attaquant
SELECT
    ROUND(AVG(p.buts), 2) AS moyenne_buts_attaquants
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
WHERE j.code_position LIKE '%AT%';


-- 5. Top 10 joueurs avec le plus de penalties marqués + % réussite
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.penalties_marques,
    p.penalties_tentes,
    ROUND(
            p.penalties_marques * 100.0 / NULLIF(p.penalties_tentes, 0),
            2
    ) AS taux_reussite_penalty
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
WHERE p.penalties_marques > 0
ORDER BY p.penalties_marques DESC, taux_reussite_penalty DESC
LIMIT 10;

-- 6. Top 10 des buteurs de Ligue 1
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.buts
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
ORDER BY p.buts DESC
LIMIT 10;

-- 7. Temps de jeu moyen par type de poste
SELECT
    pos.code_position,
    pos.libelle_position,
    ROUND(AVG(t.minutes_jouees), 2) AS moyenne_minutes_jouees,
    ROUND(AVG(t.matchs_90), 2) AS moyenne_matchs_90
FROM position pos
         JOIN joueur j ON pos.code_position = j.code_position
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
GROUP BY pos.code_position, pos.libelle_position
ORDER BY moyenne_minutes_jouees DESC;

-- 8. Joueurs avec carton rouge + % sur matchs débutés
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.cartons_rouges,
    t.matchs_titulaires,
    ROUND(
            p.cartons_rouges * 100.0 / NULLIF(t.matchs_titulaires, 0),
            2
    ) AS pourcentage_cartons_rouges_sur_titularisations
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
WHERE p.cartons_rouges > 0
ORDER BY p.cartons_rouges DESC, pourcentage_cartons_rouges_sur_titularisations DESC;

-- 9. Top 10 réussite : différence entre buts et xG
SELECT
    j.nom_joueur,
    e.nom_equipe,
    p.buts,
    a.xg,
    ROUND((p.buts::numeric - a.xg), 2) AS difference_buts_xg
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
ORDER BY difference_buts_xg DESC
LIMIT 10;

-- 10. Joueur avec le meilleur PrgP par club
SELECT
    nom_equipe,
    nom_joueur,
    prgp
FROM (
 SELECT
     e.nom_equipe,
     j.nom_joueur,
     pr.progression_passe AS prgp,
     ROW_NUMBER() OVER (
         PARTITION BY e.id_equipe
         ORDER BY pr.progression_passe DESC
     ) AS rang
 FROM joueur j
    JOIN equipe e ON j.id_equipe = e.id_equipe
    JOIN progression pr ON j.id_joueur = pr.id_joueur
) classement
WHERE rang = 1
ORDER BY prgp DESC;

-- 11. Shortlist recrutement : 10 attaquants finisseurs, salaire <= 3M€
-- Ratio = PrgP / buts
-- Classement : meilleurs buteurs d'abord, puis ratio le plus faible

WITH candidats AS (
    SELECT
        j.nom_joueur,
        e.nom_equipe,
        ROUND(s.salaire_annuel::numeric / 1000000, 2) AS salaire_millions_euros,
        p.buts,
        pr.progression_passe AS prgp,
        FLOOR(pr.progression_passe::numeric / NULLIF(p.buts, 0)) AS ratio
    FROM joueur j
             JOIN equipe e
                  ON j.id_equipe = e.id_equipe
             JOIN performance p
                  ON j.id_joueur = p.id_joueur
             JOIN progression pr
                  ON j.id_joueur = pr.id_joueur
             JOIN salaire_source s
                  ON j.id_joueur = s.id_joueur
    WHERE j.code_position LIKE '%AT%'
      AND s.salaire_annuel <= 3000000
      AND p.buts >= 5
)

SELECT
            ROW_NUMBER() OVER (
        ORDER BY buts DESC, ratio ASC, prgp ASC
        ) AS rang,
            nom_joueur,
            nom_equipe,
            salaire_millions_euros,
            buts,
            prgp,
            ratio
FROM candidats
ORDER BY
    buts DESC,
    ratio ASC,
    prgp ASC
LIMIT 10;

-- 12. Analyse complémentaire : joueurs les plus efficaces en buts par 90 minutes
SELECT
    j.nom_joueur,
    e.nom_equipe,
    j.code_position,
    p.buts,
    t.matchs_90,
    ROUND(p.buts::numeric / NULLIF(t.matchs_90, 0), 2) AS buts_par_90
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
WHERE t.matchs_90 >= 5
ORDER BY buts_par_90 DESC
LIMIT 10;

-- 13. Analyse complémentaire : joueurs avec potentiel offensif et temps de jeu limité
SELECT
    j.nom_joueur,
    e.nom_equipe,
    j.code_position,
    p.buts,
    a.xg,
    t.minutes_jouees,
    t.matchs_90,
    ROUND((p.buts::numeric - a.xg), 2) AS difference_buts_xg,
    ROUND(p.buts::numeric / NULLIF(t.matchs_90, 0), 2) AS buts_par_90,
    ROUND(a.xg / NULLIF(t.matchs_90, 0), 2) AS xg_par_90
FROM joueur j
         JOIN equipe e
              ON j.id_equipe = e.id_equipe
         JOIN performance p
              ON j.id_joueur = p.id_joueur
         JOIN attendu a
              ON j.id_joueur = a.id_joueur
         JOIN temps_de_jeu t
              ON j.id_joueur = t.id_joueur
WHERE t.matchs_90 BETWEEN 5 AND 20
  AND p.buts >= 3
ORDER BY buts_par_90 DESC, xg_par_90 DESC, difference_buts_xg DESC
LIMIT 10;

-- 14. Comparaison avec les attaquants les plus utilisés de Ligue 1
SELECT
    j.nom_joueur,
    e.nom_equipe,
    s.salaire_annuel,
    p.buts,
    a.xg,
    t.minutes_jouees,
    t.matchs_90,
    ROUND(p.buts::numeric / NULLIF(t.matchs_90, 0), 2) AS buts_par_90,
    ROUND(a.xg / NULLIF(t.matchs_90, 0), 2) AS xg_par_90,
    pr.progression_passe AS prgp,
    ROUND(pr.progression_passe::numeric / NULLIF(t.matchs_90, 0), 2) AS prgp_par_90
FROM joueur j
         JOIN equipe e
              ON j.id_equipe = e.id_equipe
         JOIN performance p
              ON j.id_joueur = p.id_joueur
         JOIN attendu a
              ON j.id_joueur = a.id_joueur
         JOIN progression pr
              ON j.id_joueur = pr.id_joueur
         JOIN temps_de_jeu t
              ON j.id_joueur = t.id_joueur
         LEFT JOIN salaire_source s
                   ON j.id_joueur = s.id_joueur
WHERE j.code_position LIKE '%AT%'
  AND t.minutes_jouees >= 1500
ORDER BY buts_par_90 DESC
LIMIT 10;