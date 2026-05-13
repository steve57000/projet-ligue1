/*
============================================================
COMPARAISON DONNÉES BRUTES VS DONNÉES CONSOLIDÉES
Projet SportDataPulse - Ligue 1 2025

Objectif :
Comparer les résultats issus des données brutes avec ceux issus
de la vue v_stats_joueurs_consolidees.

Les tables sources ne sont pas modifiées.
La consolidation est appliquée uniquement côté SQL.

Lecture :
Chaque comparaison affiche uniquement les lignes où une différence existe.
Si une requête ne retourne aucune ligne, cela signifie que la consolidation
n'a pas d'impact sur le résultat de cette requête.
============================================================
*/


-- 0. Contrôle global : nombre de lignes brut vs consolidé

SELECT
    'joueur brut' AS source,
    COUNT(*) AS nombre_lignes
FROM joueur

UNION ALL

SELECT
    'joueurs consolidés' AS source,
    COUNT(*) AS nombre_lignes
FROM v_stats_joueurs_consolidees;



-- 1. Comparaison : nombre total de buts marqués par équipe

WITH brut AS (
    SELECT
        e.nom_equipe,
        SUM(p.buts) AS total_buts_brut
    FROM equipe e
             JOIN joueur j ON e.id_equipe = j.id_equipe
             JOIN performance p ON j.id_joueur = p.id_joueur
    GROUP BY e.nom_equipe
),

     consolide AS (
         SELECT
             e.nom_equipe,
             SUM(v.buts) AS total_buts_consolide
         FROM equipe e
                  JOIN v_stats_joueurs_consolidees v ON e.id_equipe = v.id_equipe
         GROUP BY e.nom_equipe
     )

SELECT
    COALESCE(b.nom_equipe, c.nom_equipe) AS nom_equipe,
    COALESCE(b.total_buts_brut, 0) AS total_buts_brut,
    COALESCE(c.total_buts_consolide, 0) AS total_buts_consolide,
    COALESCE(c.total_buts_consolide, 0) - COALESCE(b.total_buts_brut, 0) AS ecart_buts
FROM brut b
         FULL JOIN consolide c ON b.nom_equipe = c.nom_equipe
WHERE COALESCE(b.total_buts_brut, 0) <> COALESCE(c.total_buts_consolide, 0)
ORDER BY ABS(COALESCE(c.total_buts_consolide, 0) - COALESCE(b.total_buts_brut, 0)) DESC;



-- 2. Comparaison : moyenne de matchs joués par joueur, par équipe

WITH brut AS (
    SELECT
        e.nom_equipe,
        ROUND(AVG(t.matchs_joues), 2) AS moyenne_brute
    FROM temps_de_jeu t
             JOIN joueur j ON t.id_joueur = j.id_joueur
             JOIN equipe e ON j.id_equipe = e.id_equipe
    GROUP BY e.nom_equipe
),

     consolide AS (
         SELECT
             e.nom_equipe,
             ROUND(AVG(v.matchs_joues), 2) AS moyenne_consolidee
         FROM v_stats_joueurs_consolidees v
                  JOIN equipe e ON v.id_equipe = e.id_equipe
         GROUP BY e.nom_equipe
     )

SELECT
    COALESCE(b.nom_equipe, c.nom_equipe) AS nom_equipe,
    b.moyenne_brute,
    c.moyenne_consolidee,
    ROUND(COALESCE(c.moyenne_consolidee, 0) - COALESCE(b.moyenne_brute, 0), 2) AS ecart
FROM brut b
         FULL JOIN consolide c ON b.nom_equipe = c.nom_equipe
WHERE COALESCE(b.moyenne_brute, 0) <> COALESCE(c.moyenne_consolidee, 0)
ORDER BY ABS(COALESCE(c.moyenne_consolidee, 0) - COALESCE(b.moyenne_brute, 0)) DESC;



-- 3. Comparaison : nombre de joueurs par poste et pourcentage du total

WITH brut AS (
    SELECT
        j.code_position,
        COUNT(*) AS nombre_brut,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pourcentage_brut
    FROM joueur j
    GROUP BY j.code_position
),

     consolide AS (
         SELECT
             v.code_position,
             COUNT(*) AS nombre_consolide,
             ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pourcentage_consolide
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.code_position
     )

SELECT
    COALESCE(b.code_position, c.code_position) AS code_position,
    COALESCE(b.nombre_brut, 0) AS nombre_brut,
    COALESCE(c.nombre_consolide, 0) AS nombre_consolide,
    COALESCE(c.nombre_consolide, 0) - COALESCE(b.nombre_brut, 0) AS ecart_nombre,
    b.pourcentage_brut,
    c.pourcentage_consolide,
    ROUND(COALESCE(c.pourcentage_consolide, 0) - COALESCE(b.pourcentage_brut, 0), 2) AS ecart_pourcentage
FROM brut b
         FULL JOIN consolide c ON b.code_position = c.code_position
WHERE COALESCE(b.nombre_brut, 0) <> COALESCE(c.nombre_consolide, 0)
   OR COALESCE(b.pourcentage_brut, 0) <> COALESCE(c.pourcentage_consolide, 0)
ORDER BY ABS(COALESCE(c.nombre_consolide, 0) - COALESCE(b.nombre_brut, 0)) DESC;



-- 4. Comparaison : moyenne globale de buts marqués par les attaquants

WITH brut AS (
    SELECT
        ROUND(AVG(p.buts), 2) AS moyenne_buts_attaquants_brut,
        COUNT(*) AS nb_attaquants_brut
    FROM joueur j
             JOIN performance p ON j.id_joueur = p.id_joueur
    WHERE j.code_position LIKE '%AT%'
),

     consolide AS (
         SELECT
             ROUND(AVG(v.buts), 2) AS moyenne_buts_attaquants_consolidee,
             COUNT(*) AS nb_attaquants_consolides
         FROM v_stats_joueurs_consolidees v
         WHERE v.code_position LIKE '%AT%'
     )

SELECT
    b.nb_attaquants_brut,
    c.nb_attaquants_consolides,
    b.moyenne_buts_attaquants_brut,
    c.moyenne_buts_attaquants_consolidee,
    ROUND(
            COALESCE(c.moyenne_buts_attaquants_consolidee, 0)
                - COALESCE(b.moyenne_buts_attaquants_brut, 0),
            2
    ) AS ecart_moyenne
FROM brut b
         CROSS JOIN consolide c
WHERE COALESCE(b.moyenne_buts_attaquants_brut, 0)
          <> COALESCE(c.moyenne_buts_attaquants_consolidee, 0);

-- 5. Comparaison : top 10 penalties et taux de réussite

WITH brut AS (
    SELECT
        j.nom_joueur,
        SUM(p.penalties_marques) AS penalties_marques_brut,
        SUM(p.penalties_tentes) AS penalties_tentes_brut,
        ROUND(SUM(p.penalties_marques)::numeric * 100 / NULLIF(SUM(p.penalties_tentes), 0), 2) AS taux_brut
    FROM joueur j
             JOIN performance p ON j.id_joueur = p.id_joueur
    GROUP BY j.nom_joueur
),

     consolide AS (
         SELECT
             v.nom_joueur,
             SUM(v.penalties_marques) AS penalties_marques_consolide,
             SUM(v.penalties_tentes) AS penalties_tentes_consolide,
             ROUND(SUM(v.penalties_marques)::numeric * 100 / NULLIF(SUM(v.penalties_tentes), 0), 2) AS taux_consolide
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.nom_joueur
     )

SELECT
    COALESCE(b.nom_joueur, c.nom_joueur) AS nom_joueur,
    COALESCE(b.penalties_marques_brut, 0) AS penalties_marques_brut,
    COALESCE(c.penalties_marques_consolide, 0) AS penalties_marques_consolide,
    COALESCE(b.penalties_tentes_brut, 0) AS penalties_tentes_brut,
    COALESCE(c.penalties_tentes_consolide, 0) AS penalties_tentes_consolide,
    b.taux_brut,
    c.taux_consolide,
    ROUND(COALESCE(c.taux_consolide, 0) - COALESCE(b.taux_brut, 0), 2) AS ecart_taux
FROM brut b
         FULL JOIN consolide c ON b.nom_joueur = c.nom_joueur
WHERE (
    COALESCE(b.penalties_marques_brut, 0) <> COALESCE(c.penalties_marques_consolide, 0)
        OR COALESCE(b.penalties_tentes_brut, 0) <> COALESCE(c.penalties_tentes_consolide, 0)
        OR COALESCE(b.taux_brut, 0) <> COALESCE(c.taux_consolide, 0)
    )
  AND (
    COALESCE(b.penalties_marques_brut, 0) > 0
        OR COALESCE(c.penalties_marques_consolide, 0) > 0
    )
ORDER BY ABS(COALESCE(c.taux_consolide, 0) - COALESCE(b.taux_brut, 0)) DESC;



-- 6. Comparaison : top 10 des buteurs

WITH brut AS (
    SELECT
        j.nom_joueur,
        SUM(p.buts) AS buts_brut
    FROM joueur j
             JOIN performance p ON j.id_joueur = p.id_joueur
    GROUP BY j.nom_joueur
),

     consolide AS (
         SELECT
             v.nom_joueur,
             SUM(v.buts) AS buts_consolides
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.nom_joueur
     )

SELECT
    COALESCE(b.nom_joueur, c.nom_joueur) AS nom_joueur,
    COALESCE(b.buts_brut, 0) AS buts_brut,
    COALESCE(c.buts_consolides, 0) AS buts_consolides,
    COALESCE(c.buts_consolides, 0) - COALESCE(b.buts_brut, 0) AS ecart_buts
FROM brut b
         FULL JOIN consolide c ON b.nom_joueur = c.nom_joueur
WHERE COALESCE(b.buts_brut, 0) <> COALESCE(c.buts_consolides, 0)
ORDER BY ABS(COALESCE(c.buts_consolides, 0) - COALESCE(b.buts_brut, 0)) DESC;



-- 7. Comparaison : temps de jeu moyen par type de poste

WITH brut AS (
    SELECT
        j.code_position,
        ROUND(AVG(t.minutes_jouees), 2) AS moyenne_minutes_brute,
        ROUND(AVG(t.matchs_90), 2) AS moyenne_matchs_90_brute
    FROM joueur j
             JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
    GROUP BY j.code_position
),

     consolide AS (
         SELECT
             v.code_position,
             ROUND(AVG(v.minutes_jouees), 2) AS moyenne_minutes_consolidee,
             ROUND(AVG(v.matchs_90), 2) AS moyenne_matchs_90_consolidee
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.code_position
     )

SELECT
    COALESCE(b.code_position, c.code_position) AS code_position,
    b.moyenne_minutes_brute,
    c.moyenne_minutes_consolidee,
    ROUND(COALESCE(c.moyenne_minutes_consolidee, 0) - COALESCE(b.moyenne_minutes_brute, 0), 2) AS ecart_minutes,
    b.moyenne_matchs_90_brute,
    c.moyenne_matchs_90_consolidee,
    ROUND(COALESCE(c.moyenne_matchs_90_consolidee, 0) - COALESCE(b.moyenne_matchs_90_brute, 0), 2) AS ecart_matchs_90
FROM brut b
         FULL JOIN consolide c ON b.code_position = c.code_position
WHERE COALESCE(b.moyenne_minutes_brute, 0) <> COALESCE(c.moyenne_minutes_consolidee, 0)
   OR COALESCE(b.moyenne_matchs_90_brute, 0) <> COALESCE(c.moyenne_matchs_90_consolidee, 0)
ORDER BY ABS(COALESCE(c.moyenne_minutes_consolidee, 0) - COALESCE(b.moyenne_minutes_brute, 0)) DESC;



-- 8. Comparaison : joueurs avec carton rouge et pourcentage sur matchs débutés

WITH brut AS (
    SELECT
        j.nom_joueur,
        SUM(p.cartons_rouges) AS cartons_rouges_brut,
        SUM(t.matchs_titulaires) AS matchs_titulaires_brut,
        ROUND(SUM(p.cartons_rouges)::numeric * 100 / NULLIF(SUM(t.matchs_titulaires), 0), 2) AS pourcentage_brut
    FROM joueur j
             JOIN performance p ON j.id_joueur = p.id_joueur
             JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
    GROUP BY j.nom_joueur
),

     consolide AS (
         SELECT
             v.nom_joueur,
             SUM(v.cartons_rouges) AS cartons_rouges_consolide,
             SUM(v.matchs_titulaires) AS matchs_titulaires_consolide,
             ROUND(SUM(v.cartons_rouges)::numeric * 100 / NULLIF(SUM(v.matchs_titulaires), 0), 2) AS pourcentage_consolide
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.nom_joueur
     )

SELECT
    COALESCE(b.nom_joueur, c.nom_joueur) AS nom_joueur,
    COALESCE(b.cartons_rouges_brut, 0) AS cartons_rouges_brut,
    COALESCE(c.cartons_rouges_consolide, 0) AS cartons_rouges_consolide,
    COALESCE(b.matchs_titulaires_brut, 0) AS matchs_titulaires_brut,
    COALESCE(c.matchs_titulaires_consolide, 0) AS matchs_titulaires_consolide,
    b.pourcentage_brut,
    c.pourcentage_consolide,
    ROUND(COALESCE(c.pourcentage_consolide, 0) - COALESCE(b.pourcentage_brut, 0), 2) AS ecart_pourcentage
FROM brut b
         FULL JOIN consolide c ON b.nom_joueur = c.nom_joueur
WHERE (
    COALESCE(b.cartons_rouges_brut, 0) <> COALESCE(c.cartons_rouges_consolide, 0)
        OR COALESCE(b.matchs_titulaires_brut, 0) <> COALESCE(c.matchs_titulaires_consolide, 0)
        OR COALESCE(b.pourcentage_brut, 0) <> COALESCE(c.pourcentage_consolide, 0)
    )
  AND (
    COALESCE(b.cartons_rouges_brut, 0) > 0
        OR COALESCE(c.cartons_rouges_consolide, 0) > 0
    )
ORDER BY ABS(COALESCE(c.pourcentage_consolide, 0) - COALESCE(b.pourcentage_brut, 0)) DESC;



-- 9. Comparaison : différence entre buts et xG

WITH brut AS (
    SELECT
        j.nom_joueur,
        SUM(p.buts) AS buts_brut,
        ROUND(SUM(a.xg), 2) AS xg_brut,
        ROUND(SUM(p.buts)::numeric - SUM(a.xg), 2) AS diff_brute
    FROM joueur j
             JOIN performance p ON j.id_joueur = p.id_joueur
             JOIN attendu a ON j.id_joueur = a.id_joueur
    GROUP BY j.nom_joueur
),

     consolide AS (
         SELECT
             v.nom_joueur,
             SUM(v.buts) AS buts_consolides,
             ROUND(SUM(v.xg), 2) AS xg_consolide,
             ROUND(SUM(v.buts)::numeric - SUM(v.xg), 2) AS diff_consolidee
         FROM v_stats_joueurs_consolidees v
         GROUP BY v.nom_joueur
     )

SELECT
    COALESCE(b.nom_joueur, c.nom_joueur) AS nom_joueur,
    b.buts_brut,
    c.buts_consolides,
    b.xg_brut,
    c.xg_consolide,
    b.diff_brute,
    c.diff_consolidee,
    ROUND(COALESCE(c.diff_consolidee, 0) - COALESCE(b.diff_brute, 0), 2) AS ecart_difference
FROM brut b
         FULL JOIN consolide c ON b.nom_joueur = c.nom_joueur
WHERE COALESCE(b.buts_brut, 0) <> COALESCE(c.buts_consolides, 0)
   OR COALESCE(b.xg_brut, 0) <> COALESCE(c.xg_consolide, 0)
   OR COALESCE(b.diff_brute, 0) <> COALESCE(c.diff_consolidee, 0)
ORDER BY ABS(COALESCE(c.diff_consolidee, 0) - COALESCE(b.diff_brute, 0)) DESC;



-- 10. Comparaison : meilleur PrgP par club

WITH brut_classement AS (
    SELECT
        e.nom_equipe,
        j.nom_joueur,
        pr.progression_passe AS prgp_brut,
        ROW_NUMBER() OVER (
            PARTITION BY e.id_equipe
            ORDER BY pr.progression_passe DESC
            ) AS rang
    FROM joueur j
             JOIN equipe e ON j.id_equipe = e.id_equipe
             JOIN progression pr ON j.id_joueur = pr.id_joueur
),

     brut AS (
         SELECT
             nom_equipe,
             nom_joueur,
             prgp_brut
         FROM brut_classement
         WHERE rang = 1
     ),

     consolide_classement AS (
         SELECT
             e.nom_equipe,
             v.nom_joueur,
             v.progression_passe AS prgp_consolide,
             ROW_NUMBER() OVER (
                 PARTITION BY e.id_equipe
                 ORDER BY v.progression_passe DESC
                 ) AS rang
         FROM v_stats_joueurs_consolidees v
                  JOIN equipe e ON v.id_equipe = e.id_equipe
     ),

     consolide AS (
         SELECT
             nom_equipe,
             nom_joueur,
             prgp_consolide
         FROM consolide_classement
         WHERE rang = 1
     )

SELECT
    COALESCE(b.nom_equipe, c.nom_equipe) AS nom_equipe,
    b.nom_joueur AS joueur_brut,
    b.prgp_brut,
    c.nom_joueur AS joueur_consolide,
    c.prgp_consolide,
    COALESCE(c.prgp_consolide, 0) - COALESCE(b.prgp_brut, 0) AS ecart_prgp
FROM brut b
         FULL JOIN consolide c ON b.nom_equipe = c.nom_equipe
WHERE COALESCE(b.nom_joueur, '') <> COALESCE(c.nom_joueur, '')
   OR COALESCE(b.prgp_brut, 0) <> COALESCE(c.prgp_consolide, 0)
ORDER BY ABS(COALESCE(c.prgp_consolide, 0) - COALESCE(b.prgp_brut, 0)) DESC;



-- 11. Comparaison : shortlist recrutement attaquants finisseurs
-- Ratio = PrgP / buts
-- Classement : buts décroissants, puis ratio croissant, puis PrgP croissant

WITH salaires_bruts AS (
    SELECT
        id_joueur,
        MIN(salaire_annuel) AS salaire_annuel
    FROM salaire_source
    WHERE salaire_annuel <= 3000000
      AND id_joueur IS NOT NULL
    GROUP BY id_joueur
),

     brut AS (
         SELECT
             j.nom_joueur,
             e.nom_equipe,
             ROUND(s.salaire_annuel::numeric / 1000000, 2) AS salaire_millions_euros,
             p.buts,
             pr.progression_passe AS prgp,
             FLOOR(pr.progression_passe::numeric / NULLIF(p.buts, 0))::int AS ratio
         FROM joueur j
                  JOIN equipe e ON j.id_equipe = e.id_equipe
                  JOIN performance p ON j.id_joueur = p.id_joueur
                  JOIN progression pr ON j.id_joueur = pr.id_joueur
                  JOIN salaires_bruts s ON j.id_joueur = s.id_joueur
         WHERE j.code_position LIKE '%AT%'
           AND p.buts >= 5
     ),

     brut_classement AS (
         SELECT
                     ROW_NUMBER() OVER (
                 ORDER BY buts DESC, ratio ASC, prgp ASC
                 ) AS rang_brut,
                     nom_joueur,
                     nom_equipe,
                     salaire_millions_euros,
                     buts,
                     prgp,
                     ratio
         FROM brut
     ),

     brut_top AS (
         SELECT *
         FROM brut_classement
         WHERE rang_brut <= 10
     ),

     salaires_consolides AS (
         SELECT
             nom_joueur,
             MIN(salaire_annuel) AS salaire_annuel
         FROM salaire_source
         WHERE salaire_annuel <= 3000000
         GROUP BY nom_joueur
     ),

     consolide AS (
         SELECT
             v.nom_joueur,
             STRING_AGG(DISTINCT e.nom_equipe, ', ') AS equipes,
             ROUND(MIN(s.salaire_annuel)::numeric / 1000000, 2) AS salaire_millions_euros,
             SUM(v.buts) AS buts,
             SUM(v.progression_passe) AS prgp,
             FLOOR(
                     SUM(v.progression_passe)::numeric / NULLIF(SUM(v.buts), 0)
             )::int AS ratio
         FROM v_stats_joueurs_consolidees v
                  JOIN equipe e ON v.id_equipe = e.id_equipe
                  JOIN salaires_consolides s ON s.nom_joueur = v.nom_joueur
         WHERE v.code_position LIKE '%AT%'
         GROUP BY v.nom_joueur
         HAVING SUM(v.buts) >= 5
     ),

     consolide_classement AS (
         SELECT
                     ROW_NUMBER() OVER (
                 ORDER BY buts DESC, ratio ASC, prgp ASC
                 ) AS rang_consolide,
                     nom_joueur,
                     equipes,
                     salaire_millions_euros,
                     buts,
                     prgp,
                     ratio
         FROM consolide
     ),

     consolide_top AS (
         SELECT *
         FROM consolide_classement
         WHERE rang_consolide <= 10
     )

SELECT
    COALESCE(b.nom_joueur, c.nom_joueur) AS nom_joueur,
    b.rang_brut,
    c.rang_consolide,
    b.nom_equipe AS equipe_brute,
    c.equipes AS equipe_consolidee,
    b.salaire_millions_euros AS salaire_millions_euros_brut,
    c.salaire_millions_euros AS salaire_millions_euros_consolide,
    b.buts AS buts_brut,
    c.buts AS buts_consolides,
    b.prgp AS prgp_brut,
    c.prgp AS prgp_consolide,
    b.ratio AS ratio_brut,
    c.ratio AS ratio_consolide
FROM brut_top b
         FULL JOIN consolide_top c ON b.nom_joueur = c.nom_joueur
WHERE COALESCE(b.rang_brut, 0) <> COALESCE(c.rang_consolide, 0)
   OR COALESCE(b.nom_joueur, '') <> COALESCE(c.nom_joueur, '')
   OR COALESCE(b.buts, 0) <> COALESCE(c.buts, 0)
   OR COALESCE(b.prgp, 0) <> COALESCE(c.prgp, 0)
   OR COALESCE(b.ratio, 0) <> COALESCE(c.ratio, 0)
   OR COALESCE(b.salaire_millions_euros, 0) <> COALESCE(c.salaire_millions_euros, 0)
ORDER BY COALESCE(c.rang_consolide, b.rang_brut);