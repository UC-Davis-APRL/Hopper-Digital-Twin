% Initial conditions
% NED convention: positive pd and w are downward.
% Angles are radians; angular rates are radians/second.

% Position
pn0 = 0;
pe0 = 0;
pd0 = 0;

% Body-frame velocity
u0 = 0;
v0 = 0;
w0 = 0;

% Euler angles
phi0   = 0;
theta0 = 0;
psi0   = 0;

% Body angular rates
p0 = 0;
q0 = 0;
r0 = 0;

% TVC actuator states
alpha0    = 0;
beta0     = 0;
alphadot0 = 0;
betadot0  = 0;

% Full state, ordered as expected by Dynamics.m:
% [pn; pe; pd; u; v; w; phi; theta; psi; p; q; r;
%  alpha; beta; alphadot; betadot]
x0 = [
    pn0;
    pe0;
    pd0;
    u0;
    v0;
    w0;
    phi0;
    theta0;
    psi0;
    p0;
    q0;
    r0;
    alpha0;
    beta0;
    alphadot0;
    betadot0
    ];

% Actuator initial-condition variables retained for Simulink compatibility.
IC.alpha = alpha0;
IC.beta = beta0;
IC.alphadot = alphadot0;
IC.betadot = betadot0;

x0_alpha = [IC.alpha; IC.alphadot];
x0_beta  = [IC.beta; IC.betadot];
