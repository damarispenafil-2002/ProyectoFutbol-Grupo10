USE futbol;

-- ===========================
-- Parte 1: Conociendo la Data
-- ===========================

-- ¿Cuántas competiciones diferentes existen en la base de datos?
SELECT COUNT(*) AS TotalComp -- Cuenta todas las filas en la tabla, sin importar si hay valores NULL o no
FROM competitions; -- Indica que los datos se están tomando de la tabla competitions

-- ¿Cuántas temporadas se registran en total?
SELECT COUNT(*) AS TotalSeas -- Cuenta todas las filas en la tabla, sin importar si hay valores NULL o no
FROM seasons; -- Indica que los datos se están tomando de la tabla seasons

-- ¿Cuántos equipos distintos están registrados?
SELECT COUNT(*) AS TotalTs -- Cuenta todas las filas en la tabla, sin importar si hay valores NULL o no
FROM teams; -- Indica que los datos se están tomando de la tabla teams

-- ¿Cuántos árbitros distintos aparecen en los partidos?
SELECT COUNT(DISTINCT referee_id) AS TotalRefDis -- Cuenta cuántos valores distintos hay en la columna referee_id
FROM matches -- Indica que los datos se están tomando de la tabla matches
WHERE referee_id IS NOT NULL; -- Esta condición filtra las filas de la tabla antes de hacer el conteo, ignora registros donde no se registró un árbitro

-- ==============================
-- PARTE 2: Consultas de análisis
-- ==============================

-- ¿Cuál es el equipo con mayor cantidad de partidos jugados como local?
SELECT 
	t.team_name, -- Selecciona el nombre del equipo
	COUNT(*) AS HomeMatch -- Cuenta el número total de partidos donde ese equipo fue local
FROM matches m -- Los datos se tomarán de la tabla matches(partidos)
INNER JOIN teams t ON m.home_team_id = t.team_id -- Relaciona cada partido con el equipo que jugó como local
GROUP BY t.team_name -- Agrupa los resultados por nombre de equipo y COUNT(*) contará cuántas veces cada equipo fue local
ORDER BY HomeMatch DESC -- Pone primero al equipo que más veces fue local
LIMIT 1; -- Devuelve solo la primera fila: el equipo que tuvo más partidos como local

-- ¿Cuál es el equipo con mayor cantidad de victorias en total?
SELECT t.team_name, -- Selecciona el nombre del equipo
       SUM(CASE -- Condición personalizada dentro de la consulta
             WHEN m.home_team_id = t.team_id AND m.fulltime_home > m.fulltime_away THEN 1
             -- Si el equipo fue local y ganó (goles del local > goles del visitante), suma 1
             WHEN m.away_team_id = t.team_id AND m.fulltime_away > m.fulltime_home THEN 1
             -- Si el equipo fue visitante y ganó, también suma 1
             ELSE 0 -- Sino (empató o perdió), suma 0
           END) AS TotalWins -- Da el número total de victorias para cada equipo
FROM teams t -- Los datos se tomarán de la tabla teams(equipos)
INNER JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
-- Hace que el equipo esté relacionado con los partidos donde fue local o visitante
GROUP BY t.team_name -- Agrupa los resultados por equipo, para poder contar las victorias por cada uno
ORDER BY TotalWins DESC -- Ordena de mayor a menor cantidad de victorias
LIMIT 1; -- Devuelve solo el equipo con más victorias

-- ¿Qué temporada tuvo la mayor cantidad de goles anotados (suma de todos los partidos)?
SELECT
	s.season, -- Selecciona el identificador de la temporada
    SUM(m.total_goals) AS total_goals -- Suma todos los goles de los partidos de esa temporada, total_goals ya tiene la suma de goles del equipo local y visitante para cada partido
FROM matches m -- -- Los datos se tomarán de la tabla matches(partidos)
INNER JOIN seasons s ON m.season_id = s.season_id -- La relación es por season_id, que debe existir en ambas tablas
GROUP BY s.season -- Agrupa los resultados por temporada
ORDER BY total_goals DESC -- Ordena las temporadas de mayor a menor cantidad de goles
LIMIT 1; -- Devuelve la temporada con más goles en total

-- ¿Cuál es la diferencia promedio de goles por competición?
SELECT c.competition_name, 
    AVG(ABS(m.fulltime_home - m.fulltime_away)) AS diferencia_promedio
FROM matches m
INNER JOIN seasons s ON m.season_id = s.season_id
INNER JOIN competitions c ON s.competition_code = c.competition_code
GROUP BY c.competition_name
ORDER BY diferencia_promedio DESC;

-- ¿Qué árbitro ha dirigido la mayor cantidad de partidos?
SELECT r.referee, COUNT(*) AS matches_directed
FROM matches m
JOIN referees r ON m.referee_id = r.referee_id
GROUP BY r.referee
ORDER BY matches_directed DESC
LIMIT 1;

-- ¿Qué equipo tiene un mejor promedio de goles anotados por partido en la Bundesliga?
SELECT t.team_name,
       ROUND(AVG(CASE
                   WHEN m.home_team_id = t.team_id THEN m.fulltime_home
                   WHEN m.away_team_id = t.team_id THEN m.fulltime_away
                   ELSE NULL
                 END), 2) AS PromGoals
FROM teams t
INNER JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
INNER JOIN seasons s ON M.season_id = s.season_id
INNER JOIN competitions c ON s.competition_code = c.competition_code
WHERE c.competition_name = 'Bundesliga'
GROUP BY t.team_name
ORDER BY PromGoals DESC
LIMIT 1;

-- ============================
-- Parte 3: Preguntas del Grupo
-- ============================

-- Preguntas del grupo 10 
-- ¿Cuál es el equipo con más empates?
SELECT t.team_name,
       COUNT(*) AS TotalDraws
FROM teams t
INNER JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
WHERE m.fulltime_home = m.fulltime_away
GROUP BY t.team_name
ORDER BY TotalDraws DESC
LIMIT 1;

-- ¿Cuál fue el partido con más goles anotados?
SELECT m.match_id, c.competition_name, s.season, 
       t1.team_name AS home_team, t2.team_name AS away_team,
       m.fulltime_home, m.fulltime_away,
       m.total_goals
FROM matches m
INNER JOIN seasons s ON m.season_id = s.season_id
INNER JOIN competitions c ON s.competition_code = c.competition_code
INNER JOIN teams t1 ON m.home_team_id = t1.team_id
INNER JOIN teams t2 ON m.away_team_id = t2.team_id
ORDER BY m.total_goals DESC
LIMIT 1;

-- ¿Qué equipo obtuvo más puntos como visitante?
SELECT t.team_name,
       SUM(m.away_points) AS total_away_points
FROM matches m
INNER JOIN teams t ON m.away_team_id = t.team_id
GROUP BY t.team_name
ORDER BY total_away_points DESC
LIMIT 10;

-- ¿Cuál es el promedio de goles recibidos por equipo?
SELECT t.team_name,
       ROUND(AVG(CASE
                   WHEN m.home_team_id = t.team_id THEN m.fulltime_away
                   WHEN m.away_team_id = t.team_id THEN m.fulltime_home
                   ELSE NULL
                 END), 2) AS avg_goals_conceded
FROM teams t
INNER JOIN matches M ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
GROUP BY t.team_name
ORDER BY avg_goals_conceded DESC;

-- ¿Qué equipos han jugado más partidos en total?
SELECT t.team_name,
       COUNT(*) AS total_matches
FROM teams t
INNER JOIN matches m ON t.team_id = m.home_team_id OR t.team_id = m.away_team_id
GROUP BY t.team_name
ORDER BY total_matches DESC
LIMIT 5;



