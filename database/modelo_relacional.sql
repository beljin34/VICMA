PRAGMA foreign_keys = ON;

-- Modelo relacional del sistema VICMA
-- Base compatible con SQLite

CREATE TABLE administradores (
    id_administrador INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    usuario TEXT NOT NULL UNIQUE,
    contrasena TEXT NOT NULL
);

CREATE TABLE camaras_ip (
    id_camara INTEGER PRIMARY KEY AUTOINCREMENT,
    id_administrador INTEGER,
    nombre TEXT NOT NULL,
    direccion_ip TEXT NOT NULL,
    puerto INTEGER NOT NULL,
    url_rtsp TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'ACTIVA',
    FOREIGN KEY (id_administrador) REFERENCES administradores(id_administrador)
);

CREATE TABLE flujos_video (
    id_flujo INTEGER PRIMARY KEY AUTOINCREMENT,
    id_camara INTEGER NOT NULL,
    fecha_inicio TEXT NOT NULL,
    estado TEXT NOT NULL,
    fps INTEGER,
    FOREIGN KEY (id_camara) REFERENCES camaras_ip(id_camara)
);

CREATE TABLE fotogramas (
    id_fotograma INTEGER PRIMARY KEY AUTOINCREMENT,
    id_flujo INTEGER NOT NULL,
    numero INTEGER NOT NULL,
    fecha_hora TEXT NOT NULL,
    imagen TEXT,
    FOREIGN KEY (id_flujo) REFERENCES flujos_video(id_flujo)
);

CREATE TABLE detecciones (
    id_deteccion INTEGER PRIMARY KEY AUTOINCREMENT,
    id_fotograma INTEGER NOT NULL,
    clase TEXT NOT NULL,
    confianza REAL NOT NULL,
    coordenada_x REAL,
    coordenada_y REAL,
    ancho REAL,
    alto REAL,
    FOREIGN KEY (id_fotograma) REFERENCES fotogramas(id_fotograma)
);

CREATE TABLE personas (
    id_persona INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_clase TEXT NOT NULL DEFAULT 'persona',
    confianza REAL NOT NULL
);

CREATE TABLE seguimientos (
    id_seguimiento INTEGER PRIMARY KEY AUTOINCREMENT,
    id_persona INTEGER NOT NULL,
    id_camara INTEGER NOT NULL,
    id_tracking INTEGER NOT NULL UNIQUE,
    estado TEXT NOT NULL,
    fecha_inicio TEXT NOT NULL,
    fecha_fin TEXT,
    FOREIGN KEY (id_persona) REFERENCES personas(id_persona),
    FOREIGN KEY (id_camara) REFERENCES camaras_ip(id_camara)
);

CREATE TABLE trayectorias (
    id_trayectoria INTEGER PRIMARY KEY AUTOINCREMENT,
    id_seguimiento INTEGER NOT NULL,
    distancia_recorrida REAL DEFAULT 0,
    tiempo_permanencia REAL DEFAULT 0,
    FOREIGN KEY (id_seguimiento) REFERENCES seguimientos(id_seguimiento)
);

CREATE TABLE puntos_trayectoria (
    id_punto INTEGER PRIMARY KEY AUTOINCREMENT,
    id_trayectoria INTEGER NOT NULL,
    x REAL NOT NULL,
    y REAL NOT NULL,
    fecha_hora TEXT NOT NULL,
    FOREIGN KEY (id_trayectoria) REFERENCES trayectorias(id_trayectoria)
);

CREATE TABLE conductas (
    id_conducta INTEGER PRIMARY KEY AUTOINCREMENT,
    id_seguimiento INTEGER NOT NULL,
    tipo_conducta TEXT NOT NULL,
    clasificacion TEXT NOT NULL CHECK (clasificacion IN ('NORMAL', 'SOSPECHOSA')),
    confianza REAL,
    fecha_hora TEXT NOT NULL,
    observacion TEXT,
    FOREIGN KEY (id_seguimiento) REFERENCES seguimientos(id_seguimiento)
);

-- SELECT 1: ¿Qué cámaras se encuentran activas para el monitoreo?
SELECT
    id_camara,
    nombre,
    direccion_ip,
    puerto,
    estado
FROM camaras_ip
WHERE estado = 'ACTIVA';

-- SELECT 2: ¿Qué conductas sospechosas fueron detectadas y en qué cámara?
SELECT
    c.fecha_hora,
    c.tipo_conducta,
    c.confianza,
    cam.nombre AS camara,
    s.id_tracking
FROM conductas AS c
INNER JOIN seguimientos AS s
    ON c.id_seguimiento = s.id_seguimiento
INNER JOIN camaras_ip AS cam
    ON s.id_camara = cam.id_camara
WHERE c.clasificacion = 'SOSPECHOSA'
ORDER BY c.fecha_hora DESC;
