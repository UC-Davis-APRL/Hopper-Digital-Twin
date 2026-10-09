function xdot = Dynamics(x,u_in,P)

%% constants
g = P.g;
m = P.m;

I = P.I;

rT = P.rT;

Jalpha = P.Jalpha;
Jbeta  = P.Jbeta;

omegaAlpha = P.omegaAlpha;
omegaBeta  = P.omegaBeta;

zetaAlpha = P.zetaAlpha;
zetaBeta  = P.zetaBeta;

%% states
pn = x(1);
pe = x(2);
pd = x(3);

u = x(4);
v = x(5);
w = x(6);

phi   = x(7);
theta = x(8);
psi   = x(9);

p = x(10);
q = x(11);
r = x(12);

alpha = x(13);
beta  = x(14);

alphadot = x(15);
betadot  = x(16);


%% inputs
alpha_cmd = u_in(1);
beta_cmd = u_in(2);
T = u_in(3);


%% helpers

cphi = cos(phi);
sphi = sin(phi);

cth = cos(theta);
sth = sin(theta);

cpsi = cos(psi);
spsi = sin(psi);

R_b_i = [
    cpsi*cth, cpsi*sth*sphi - spsi*cphi, cpsi*sth*cphi + spsi*sphi;
    spsi*cth, spsi*sth*sphi + cpsi*cphi, spsi*sth*cphi - cpsi*sphi;
    -sth,     cth*sphi,                  cth*cphi
];

R_i_b = R_b_i.';



FT = T * [
    sin(beta);
    -sin(alpha)*cos(beta);
    -cos(alpha)*cos(beta)
    ];

%% Actuators

alphaddot = ...
    -2*zetaAlpha*omegaAlpha*alphadot ...
    -omegaAlpha^2*alpha ...
    +omegaAlpha^2*alpha_cmd;

betaddot = ...
    -2*zetaBeta*omegaBeta*betadot ...
    -omegaBeta^2*beta ...
    +omegaBeta^2*beta_cmd;



%% Position
posdot = R_b_i*[u;v;w];

pndot = posdot(1);
pedot = posdot(2);
pddot = posdot(3);

%% Velocity

Fg = m*g*[
    -sin(theta);
    cos(theta)*sin(phi);
    cos(theta)*cos(phi)
    ];

vdot_body = ...
    Fg/m + FT/m + ...
    [r*v - q*w;
    p*w - r*u;
    q*u - p*v];

udot = vdot_body(1);
vdot = vdot_body(2);
wdot = vdot_body(3);

%% Angles

eulerdot = [
    1 sin(phi)*tan(theta) cos(phi)*tan(theta);
    0 cos(phi)           -sin(phi);
    0 sin(phi)/cos(theta) cos(phi)/cos(theta)
    ]*[p;q;r];

phidot   = eulerdot(1);
thetadot = eulerdot(2);
psidot   = eulerdot(3);

%% Rates
omega = [p;q;r];

tau_thrust = cross(rT,FT);

tau_tvc = [
    Jalpha*alphaddot;
    Jbeta*betaddot*cos(alpha);
    Jbeta*betaddot*sin(alpha)
    ];

tau = tau_thrust + tau_tvc;

omegadot = I \ (tau - cross(omega,I*omega));

pdot = omegadot(1);
qdot = omegadot(2);
rdot = omegadot(3);

%% derivative vector assembly

xdot = zeros(16,1);

xdot(1)  = pndot;
xdot(2)  = pedot;
xdot(3)  = pddot;

xdot(4)  = udot;
xdot(5)  = vdot;
xdot(6)  = wdot;

xdot(7)  = phidot;
xdot(8)  = thetadot;
xdot(9)  = psidot;

xdot(10) = pdot;
xdot(11) = qdot;
xdot(12) = rdot;

xdot(13) = alphadot;
xdot(14) = betadot;
xdot(15) = alphaddot;
xdot(16) = betaddot;