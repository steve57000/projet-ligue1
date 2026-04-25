SELECT COUNT(*) FROM joueur;
SELECT COUNT(*) FROM equipe;
SELECT COUNT(*) FROM performance;

-- 1. Nombre total de buts marqués par équipe
SELECT
    e.nom_equipe,
    SUM(p.buts) AS total_buts
FROM equipe e
         JOIN joueur j ON e.id_equipe = j.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
GROUP BY e.nom_equipe
ORDER BY total_buts DESC;
-- 2. Nombre de matchs joués en moyenne par joueur en L1
SELECT
    ROUND(AVG(t.matchs_joues), 2) AS moyenne_matchs_joues_l1
FROM temps_de_jeu t;
-- 3. Nombre de postes et % du total général pour chaque poste
SELECT
    pos.code_position,
    pos.libelle_position,
    COUNT(j.id_joueur) AS nombre_joueurs,
    ROUND(
            COUNT(j.id_joueur) * 100.0 / SUM(COUNT(j.id_joueur)) OVER (),
            2
    ) AS pourcentage_total
FROM position pos
         JOIN joueur j ON pos.code_position = j.code_position
GROUP BY pos.code_position, pos.libelle_position
ORDER BY nombre_joueurs DESC;
-- 4. Nombre de buts moyen marqués par un attaquant uniquement
SELECT
    ROUND(AVG(p.buts), 2) AS moyenne_buts_attaquants
FROM joueur j
         JOIN performance p ON j.id_joueur = p.id_joueur
WHERE j.code_position = 'AT';
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
-- 10. Joueur avec le meilleur PrgP
SELECT
    j.nom_joueur,
    e.nom_equipe,
    pr.progression_passe AS prgp
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN progression pr ON j.id_joueur = pr.id_joueur
ORDER BY pr.progression_passe DESC
LIMIT 1;
-- 11. Shortlist recrutement : 10 attaquants finisseurs, salaire <= 3M€
SELECT
    j.nom_joueur,
    e.nom_equipe,
    s.salaire_annuel,
    p.buts,
    a.xg,
    ROUND((p.buts::numeric - a.xg), 2) AS difference_buts_xg,
    pr.progression_passe AS prgp,
    t.minutes_jouees,
    ROUND(p.buts::numeric / NULLIF(t.matchs_90, 0), 2) AS buts_par_90
FROM joueur j
         JOIN equipe e ON j.id_equipe = e.id_equipe
         JOIN performance p ON j.id_joueur = p.id_joueur
         JOIN attendu a ON j.id_joueur = a.id_joueur
         JOIN progression pr ON j.id_joueur = pr.id_joueur
         JOIN temps_de_jeu t ON j.id_joueur = t.id_joueur
         JOIN salaire_source s ON j.id_joueur = s.id_joueur
WHERE j.code_position = 'AT'
  AND s.salaire_annuel <= 3000000
  AND t.matchs_90 > 0
ORDER BY
    buts_par_90 DESC,
    difference_buts_xg DESC,
    prgp ASC
LIMIT 10;