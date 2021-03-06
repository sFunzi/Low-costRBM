function model = training_bipolar_rbm(conf,data_file)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training RBM                                                       %  
% conf: training setting                                             %
% W: weights of connections                                          %
% mW: mask of connections                                            %
% -*-sontran2012-*-                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
vars = whos('-file', data_file);
A = load(data_file,vars(1).name);
data = A.(vars(1).name);
assert(~isempty(data),'[KBRBM] Data is empty'); 
%% convert 0:1 to -1:1
data = 2*data-1;
%% initialization
visNum  = size(data,2);
hidNum  = conf.hidNum;
sNum  = conf.sNum;
lr    = conf.params(1);
N     = 10;                                                                     % Number of epoch training with lr_1                     
W     = 0.1*randn(visNum,hidNum);


DW    = zeros(size(W));
visB  = zeros(1,visNum);
DVB   = zeros(1,visNum);
hidB  = zeros(1,hidNum);
DHB   = zeros(1,hidNum);
%% Reconstruction error & evaluation error & early stopping
mse    = 0;
omse   = 0;
inc_count = 0;
MAX_INC = 3000;                                                                % If the error increase MAX_INC times continuously, then stop training
%% Average best settings
n_best  = 1;
aW  = size(W);
aVB = size(visB);
aHB = size(hidB);
%% Plotting
h = plot(nan);
%% ==================== Start training =========================== %%
for i=1:conf.eNum
    if i== N+1
        lr = conf.params(2);
    end
    omse = mse;
    mse = 0;
    for j=1:conf.bNum
       visP = data((j-1)*conf.sNum+1:j*conf.sNum,:);
       %up
       hidP = logistic(2*(visP*W + repmat(hidB,sNum,1)));
       hidPs =  1*(hidP >rand(sNum,hidNum));
       hidPs = 2*hidPs - 1;
       hidNs = hidPs;
       for k=1:conf.gNum
           % down
           visN  = logistic(2*(hidNs*W' + repmat(visB,sNum,1)));
           visNs = 1*(visN>rand(sNum,visNum));
           visNs = 2*visNs - 1;
%            if j==5 && k==1, observe_reconstruction(visN,sNum,i,28,28); end
           % up
           hidN  = logistic(2*(visNs*W + repmat(hidB,sNum,1)));
           hidNs = 1*(hidN>rand(sNum,hidNum));
           hidNs = 2*hidNs - 1;
       end
       hidP = 2*hidP -1;
       hidN = 2*hidN -1;
       visN = 2*visN - 1;
       % Compute MSE for reconstruction
       rdiff = (visP - visN);
       mse = mse + sum(sum(rdiff.*rdiff))/(sNum*visNum);
       % Update W,visB,hidB
       diff = (visP'*hidP - visNs'*hidN)/sNum;
       DW  = lr*(diff - conf.params(4)*W) +  conf.params(3)*DW;
       W   = W + DW;
       DVB  = lr*sum(visP - visN,1)/sNum + conf.params(3)*DVB;
       visB = visB + DVB;
       DHB  = lr*sum(hidP - hidN,1)/sNum + conf.params(3)*DHB;
       hidB = hidB + DHB;
    end
    %% Testing XOR only
%      visP(3) = 0;
%      hidP = 1*(logistic(visP*W + repmat(hidB,sNum,1))>rand(sNum,hidNum));
%       visN = logistic(hidP*W' + repmat(visB,sNum,1))
%     fprintf('XOR Testing %f\n',sum(sum(visN(:,3) - data(:,3))));
%     visN
    %% 
    mse_plot(i) = mse;
    axis([0 (conf.eNum+1) 0 10]);
    set(h,'YData',mse_plot);
    drawnow;
%    plot(mse_plot,'XDataSource','real(mse_plot)','YDataSource','imag(mse_plot)')
%     linkdata on;
    
    if mse > omse
        inc_count = inc_count + 1;
    else
        inc_count = 0;
    end
    if inc_count> MAX_INC, break; end;
    fprintf('Epoch %d  : MSE = %f\n',i,mse);
end

model.W = W;
model.visB = visB;
model.hidB = hidB;
end