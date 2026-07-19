-- Vue consolidée des statistiques joueurs
-- Objectif : fusionner les lignes appartenant à un même joueur,
-- même poste et même équipe, sans modifier les données sources.

CREATE OR REPLACE VIEW v_stats_joueurs_consolidees AS
SELECT
    MIN(j.id_joueur) AS id_joueur_reference,
    j.nom_joueur,
    j.code_position,
    j.id_equipe,

    SUM(p.buts) AS buts,
    SUM(p.passes_decisives) AS passes_decisives,
    SUM(p.penalties_marques) AS penalties_marques,
    SUM(p.penalties_tentes) AS penalties_tentes,
    SUM(p.cartons_jaunes) AS cartons_jaunes,
    SUM(p.cartons_rouges) AS cartons_rouges,

    SUM(t.matchs_joues) AS matchs_joues,
    SUM(t.matchs_titulaires) AS matchs_titulaires,
    SUM(t.minutes_jouees) AS minutes_jouees,
    SUM(t.matchs_90) AS matchs_90,

    SUM(a.xg) AS xg,
    SUM(a.npxg) AS npxg,
    SUM(a.xag) AS xag,

    SUM(pr.progression_conduite) AS progression_conduite,
    SUM(pr.progression_passe) AS progression_passe,
    SUM(pr.progression_course) AS progression_course

FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
         JOIN progression pr ON j.id_joueur = pr.id_joueur

GROUP BY
    j.nom_joueur,
    j.code_position,
    j.id_equipe;


-- Contrôle : nombre de lignes avant / après consolidation

SELECT
    'joueurs bruts' AS source,
    COUNT(*) AS nombre_lignes
FROM joueur

UNION ALL

SELECT
    'joueurs consolidés' AS source,
    COUNT(*) AS nombre_lignes
FROM v_stats_joueurs_consolidees;


-- Requêtes consolidées

-- 2. Nombre de matchs joués en moyenne par joueur, par équipe
SELECT
    e.nom_equipe AS equipe,
    ROUND(AVG(v.matchs_joues), 2) AS moyenne_matchs_joues_par_joueur
FROM v_stats_joueurs_consolidees v
         JOIN equipe e ON v.id_equipe = e.id_equipe
GROUP BY e.nom_equipe
ORDER BY moyenne_matchs_joues_par_joueur DESC;


-- 3. Nombre de postes et pourcentage du total général
SELECT
    v.code_position,
    COUNT(*) AS nombre_joueurs,
    ROUND(
            COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
            2
    ) AS pourcentage_total
FROM (
         SELECT
             nom_joueur,
             code_position
         FROM v_stats_joueurs_consolidees
         GROUP BY nom_joueur, code_position
     ) v
GROUP BY v.code_position
ORDER BY nombre_joueurs DESC;


-- 4. Nombre moyen de buts marqués par un attaquant - version consolidée
SELECT
    ROUND(AVG(v.buts), 2) AS moyenne_buts_attaquants
FROM v_stats_joueurs_consolidees v
WHERE v.code_position LIKE '%AT%';


-- 6. Top 10 des buteurs de Ligue 1
SELECT
    v.nom_joueur,
    STRING_AGG(DISTINCT e.nom_equipe, ', ') AS equipes,
    SUM(v.buts) AS total_buts
FROM v_stats_joueurs_consolidees v
         JOIN equipe e ON v.id_equipe = e.id_equipe
GROUP BY v.nom_joueur
ORDER BY total_buts DESC
LIMIT 10;


-- 7. Temps de jeu moyen par type de poste
SELECT
    v.code_position,
    ROUND(AVG(v.minutes_jouees), 2) AS moyenne_minutes_jouees,
    ROUND(AVG(v.matchs_90), 2) AS moyenne_matchs_90
FROM (
         SELECT
             nom_joueur,
             code_position,
             SUM(minutes_jouees) AS minutes_jouees,
             SUM(matchs_90) AS matchs_90
         FROM v_stats_joueurs_consolidees
         GROUP BY nom_joueur, code_position
     ) v
GROUP BY v.code_position
ORDER BY moyenne_minutes_jouees DESC;


-- 9. Top 10 réussite : différence entre buts et xG
SELECT
    v.nom_joueur,
    STRING_AGG(DISTINCT e.nom_equipe, ', ') AS equipes,
    SUM(v.buts) AS total_buts,
    ROUND(SUM(v.xg), 2) AS total_xg,
    ROUND(SUM(v.buts)::numeric - SUM(v.xg), 2) AS difference_buts_xg
FROM v_stats_joueurs_consolidees v
         JOIN equipe e ON v.id_equipe = e.id_equipe
GROUP BY v.nom_joueur
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
             v.nom_joueur,
             v.progression_passe AS prgp,
             ROW_NUMBER() OVER (
                 PARTITION BY e.id_equipe
                 ORDER BY v.progression_passe DESC
                 ) AS rang
         FROM v_stats_joueurs_consolidees v
                  JOIN equipe e ON v.id_equipe = e.id_equipe
     ) classement
WHERE rang = 1
ORDER BY prgp DESC;


-- 11. Shortlist recrutement : 10 attaquants finisseurs, salaire inférieur ou égal à 3M€
-- Ratio = PrgP / buts
-- Classement : meilleurs buteurs d'abord, puis ratio le plus faible, puis PrgP le plus faible

WITH candidats AS (
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
             JOIN equipe e
                  ON v.id_equipe = e.id_equipe
             JOIN salaire_source s
                  ON s.id_joueur = v.id_joueur_reference
    WHERE v.code_position LIKE '%AT%'
      AND s.salaire_annuel <= 3000000
    GROUP BY v.nom_joueur
    HAVING SUM(v.buts) >= 5
),

     classement AS (
         SELECT
                     ROW_NUMBER() OVER (
                 ORDER BY buts DESC, ratio ASC, prgp ASC
                 ) AS rang,
                     nom_joueur,
                     equipes,
                     salaire_millions_euros,
                     buts,
                     prgp,
                     ratio
         FROM candidats
     )

SELECT
    rang,
    nom_joueur,
    equipes,
    salaire_millions_euros,
    buts,
    prgp,
    ratio
FROM classement
WHERE rang <= 10
ORDER BY rang;

