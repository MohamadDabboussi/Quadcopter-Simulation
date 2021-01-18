% NOTE: This srcipt will not run as expected unless you fill in proper
% code in trajhandle and controlhandle
% You should not modify any part of this script except for the
% visualization part

function [QP] = Run_Keyboard_control(h_3d,trajhandle,qn,Datat,Speed,opt)
Data=[0 0 0];
addpath('utils')
addpath('trajectories')

% controller
controlhandle = @controller;
% real-time 
real_time = true;
% max time
time_tol = 50;%25
% parameters for simulation
params = crazyflie();

%% **************************** FIGURES *****************************
quadcolors = lines(qn);
%% *********************** INITIAL CONDITIONS ***********************
max_iter  = 10000;      % max iteration%5000
starttime = 0;         % start of simulation in seconds
tstep     = 0.01;      % this determines the time step at which the solution is given
cstep     = 0.05;      % image capture time interval
nstep     = cstep/tstep;
time      = starttime; % current time
err       = []; % runtime errors

% Get start and stop position
 des_start = trajhandle(0, qn);
 des_stop  = trajhandle(inf, qn);
 stop{qn}  = des_stop.pos;
% 
x0{qn}    = init_state( des_start.pos, 0 );
xtraj{qn} = zeros(max_iter*nstep, length(x0{qn}));
ttraj{qn} = zeros(max_iter*nstep, 1);

x         = x0;        % state

pos_tol   = 0.01;
vel_tol   = 0.01;

%% ************************* RUN SIMULATION *************************
% Main loop
for iter = 1:max_iter
    Data=evalin('base', 'Data');
%    title(h_3d,sprintf('iteration: %d, time: %4.2f', iter, time));
    tic;

    timeint = time:tstep:time+cstep;
        % Initialize quad plot
        if iter==1
        QP{qn} = QuadPlot(qn, x0{qn}, 0.1, 0.04, quadcolors(qn,:), max_iter, h_3d);
        
        desired_state = trajhandle(time, qn);
        QP{qn}.UpdateQuadPlot(x{qn}, [desired_state.pos; desired_state.vel], time); 
        end

    FV = @(t,s) quadEOM(t, s, qn, controlhandle, trajhandle, params,Data);
    % Run simulation
    [tsave, xsave] = ode45(FV , timeint, x{qn});
    x{qn}    = xsave(end, :)';
        
    % Save to traj
    xtraj{qn}((iter-1)*nstep+1:iter*nstep,:) = xsave(1:end-1,:);
    ttraj{qn}((iter-1)*nstep+1:iter*nstep) = tsave(1:end-1);
    
    pause(0.1);
    % Update quad plot
    tt =time + cstep;
    desired_state = trajhandle(tt, qn);
    hold(h_3d,'on')
    QP{qn}.UpdateQuadPlot(x{qn}, [desired_state.pos; desired_state.vel], tt);
    hold(h_3d,'off')   
    
    time = time + cstep; % Update simulation time
    t = toc;

    % Pause to make real-time
    if real_time && (t < cstep)
        pause(cstep - t);
    end

    % Check termination criteria
%     if terminate_check(x, time, stop, pos_tol, vel_tol, time_tol,qn)
%         break
%     end
 end
fprintf('finished.\n')