USE ophidiadb;

INSERT INTO host (hostname, cores, memory) VALUES ('127.0.0.1',4,1);

INSERT INTO dbmsinstance (idhost, login, password, port) VALUES (1, 'root', 'root', 3306);

INSERT INTO hostpartition (partitionname) VALUES ('test');

INSERT INTO hashost VALUES (1,1);


