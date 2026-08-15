P.g = 9.81;

P.m = 0.793;

P.Ixx = 0.02;
P.Iyy = 0.021;
P.Izz = 0.005;

P.I = diag([P.Ixx,P.Iyy,P.Izz])

xT=0;
yT=0;
zT=0.2;

P.rT = [xT; yT; zT];

P.Jalpha = 0.001;
P.Jbeta  = 0.001;

P.omegaAlpha = 10;
P.omegaBeta  = 10;

P.zetaAlpha = 0.7;
P.zetaBeta  = 0.7;