%Section 1: Sets parameters for all calibration methods 
clc,clear,format compact
Dim=2;
Case=3;
nl=18;
nh=6;
nh0=12;
RatioCost=3;
InitialBudget=nl*1+nh*RatioCost;
InitialBudget0=nh0*RatioCost;
Budget=InitialBudget+12;
load Example3.mat MultiDataInput SingleDataInput XTrue yh_XTrue PhysData
% load Example3.mat
% XTrue=[0.1 0.4];
% [yh_XTrue]= Simulator(XTrue,2,Case);
% std_error=(var(yh_XTrue)*0.0001)^0.5;
% PhysData=yh_XTrue+normrnd(0,std_error,size(yh_XTrue));
SSE_XTrue=sum([Simulator(XTrue,2,Case)-PhysData].^2);

[X1,X2]=meshgrid(linspace(0,1,51)');
TestPoints= [X1(:) X2(:)];
for id=1:size(TestPoints,1)
    TrueSh(id,1)=sum((Simulator(TestPoints(id,:),2,Case)-PhysData).^2); 
end
[~,sortidx]=sort(TrueSh);

lb=0*ones(1,Dim);
ub=1*ones(1,Dim);
options=optimoptions('patternsearch','MaxIterations',10^6,'MeshTolerance',10^-6,'TolFun',10^-8,'TolX',10^-8,'MaxFunEvals',10^8);

SSHFun=@(x) sum([Simulator(x,2,Case)-PhysData].^2);
for id=1:50
    StartPoint= TestPoints(sortidx(id),:);
    [XMLETry(id,:),fval(id,:)]=patternsearch(SSHFun,StartPoint,[],[],[],[],lb,ub,[],options)  ;
end
[~,minidx]=min(fval);
XMLE=XMLETry(minidx,:);
SSE_XMLE=min(fval);
%{
parfor id=1:100
    id
    [Dl,Dh]=GenerateNestedLHD(nl,nh,Dim,1e5);     
    [Dh0]=GenerateNestedLHD(nh0,nh0,Dim,1e5);     
    
    Dls(:,:,id)=Dl;
    Dhs(:,:,id)=Dh;
    Dh0s(:,:,id)=Dh0;    
end


for id=1:100
    id

    Dl=Dls(:,:,id);
    Dh=Dhs(:,:,id);
    Dh0=Dh0s(:,:,id);
    
    clear Yl Yh
    for jd=1:nl
        Yl(jd,:)=Simulator(Dl(jd,:),1,Case);
    end
    for jd=1:nh
        Yh(jd,:)=Simulator(Dh(jd,:),2,Case);
    end
    clear  Yh0
    for jd=1:nh0
        Yh0(jd,:)=Simulator(Dh0(jd,:),2,Case);
    end
    
    MultiDataInput(id).Dl=Dl;       MultiDataInput(id).Yl=Yl;
    MultiDataInput(id).Dh= Dh;    MultiDataInput(id).Yh=Yh;
    MultiDataInput(id).XTrue=XTrue;
    MultiDataInput(id).PhysData=PhysData;    MultiDataInput(id).RatioCost=RatioCost;
    MultiDataInput(id).Budget=Budget;           MultiDataInput(id).Case=Case;
    
    SingleDataInput(id).Dl =[] ;       SingleDataInput(id).Yl=[];
    SingleDataInput(id).Dh= Dh0;    SingleDataInput(id).Yh=Yh0;
    SingleDataInput(id).XTrue=XTrue;
    SingleDataInput(id).PhysData=PhysData;    SingleDataInput(id).RatioCost=RatioCost;
    SingleDataInput(id).Budget=Budget;          SingleDataInput(id).Case=Case;
end
%}
Trainidx =45;
Yl = MultiDataInput(Trainidx).Yl(1:nh,:);
Yh = MultiDataInput(Trainidx).Yh;

Sl=sum( [Yl-PhysData].^2,2);
Sh=sum( [Yh-PhysData].^2,2);

clear AaGrid
Ones=ones(nh,1);
for kd=1:numel(PhysData)
    if all(Yl(:,kd)<10^(-12)) %only for example 3
        AaGrid(:,kd)=[0,1];
        Sum_ErrorYlYh0=sum(abs(Yh(:,kd)-Yl(:,kd))) ;
        if Sum_ErrorYlYh0>0
            return
        end
    else
        AaGrid(:,kd)=regress(Yh(:,kd),[Ones,Yl(:,kd)]);
    end
end

[X1,X2]=meshgrid(linspace(0,1,501)');
for id=1:size(X1,1)
    for jd=1:size(X1,2)
        yl0=Simulator([X1(id,jd),X2(id,jd)],1,Case);
        yh0=Simulator([X1(id,jd),X2(id,jd)],2,Case);
        YlModifiedGrid=AaGrid(1,:)+yl0.*AaGrid(2,:);
        
        fLFSSEModified(id,jd)=sum((YlModifiedGrid-PhysData).^2); 
        
        fLFSSE(id,jd)=sum([yl0-PhysData].^2); 
        fHFSSE(id,jd)=sum([yh0-PhysData].^2); 
    end
end


Levels=1*[  3 10 25 50 100 250 500 1000 1500 2.5e3 6e3  12e3   24e3 40e3 ] ;
Fontsize2=32;
FontSizeLevels=30;
figure,clf
tiledlayout(1,3,'Padding','none','TileSpacing','none');
nexttile
grid on
[C,h] = contour(X1,X2,fLFSSE,Levels,'TextStep',2,'linewidth',4);
clabel(C,h,'FontWeight','bold','FontSize',FontSizeLevels,'Color','k','linewidth',2)
clabel(C,h,'LabelSpacing',155,'FontWeight','bold','FontSize',FontSizeLevels,'Color','k','linewidth',2)
text(0.47,-0.17,'x_1','FontSize',Fontsize2,'FontWeight','Bold')
ylabel('x_2','FontSize',Fontsize2,'Rotation',0,'HorizontalAlignment','right')
title('(a)','FontSize',Fontsize2,'FontWeight','Bold')
xticks([0:0.2:1])
yticks([0:0.2:1])
set(gca,'FontWeight','bold','FontSize',Fontsize2)
grid on
 
nexttile
[C,h] = contour(X1,X2,fHFSSE,Levels,'linewidth',4);
clabel(C,h,'LabelSpacing',200,'FontWeight','bold','FontSize',FontSizeLevels,'Color','k','linewidth',2)
text(0.47,-0.17,'x_1','FontSize',Fontsize2,'FontWeight','Bold')
ylabel('x_2','FontSize',Fontsize2,'Rotation',0,'HorizontalAlignment','right')
title('(b)','FontSize',Fontsize2,'FontWeight','Bold')
xticks([0:0.2:1])
yticks([0:0.2:1])
set(gca,'FontWeight','bold','FontSize',Fontsize2)
grid on

nexttile
[C,h] = contour(X1,X2,fLFSSEModified,Levels,'TextStepMode','manual','linewidth',4);
clabel(C,h,'LabelSpacing',200,'FontWeight','bold','FontSize',FontSizeLevels,'Color','k','linewidth',2)
xlabel(' ','FontSize',Fontsize2)
text(0.47,-0.17,'x_1','FontSize',Fontsize2,'FontWeight','Bold')
ylabel('x_2','FontSize',Fontsize2,'Rotation',0,'HorizontalAlignment','right')
title('(c)','FontSize',Fontsize2,'FontWeight','Bold')
xticks([0:0.2:1])
yticks([0:0.2:1])
set(gca,'FontWeight','bold','FontSize',Fontsize2)
grid on
set(findobj(gca,'type','line'),'linew',4)
set(gcf,'position'  ,[          0 150         1886         631])
set(findobj(gcf,'type','axes'),'FontWeight','Bold', 'LineWidth', 3); 

    


%%
%Section 2: Bayesian optimization
ZNBC_BC=1;   ZNBC_ID=0;   ZNBC_SR=2;
ZMLFSSE=1;   ZLFSSE=0; Val=1; percentage=0.99; 
for id=1:100
    id
    T_MBC_AGP{id,1} =CalibrationAGP(MultiDataInput(id),ZNBC_BC,ZMLFSSE,Val); 'MBC-AGP'
    T_BC_AGP{id,1} =CalibrationAGP(MultiDataInput(id),ZNBC_BC,ZLFSSE,Val); 'BC-AGP'
    T_MID_AGP{id,1} =CalibrationAGP(MultiDataInput(id),ZNBC_ID,ZMLFSSE,Val); 'MID-AGP'
    T_SR_AGP{id,1} =CalibrationAGP(MultiDataInput(id),ZNBC_SR,ZLFSSE,Val); 'SR-AGP'
    T_Nested{id,1} =CalibrationNested(MultiDataInput(id),Val); 'Nested'
    T_SVDAGP{id,1} =CalibrationSVDAGP(MultiDataInput(id),Val,percentage);'SVD-AGP'
    T_BC_GP{id,1} =CalibrationBCGP(SingleDataInput(id),Val); 'BC-GP'
    T_SR_GP{id,1} =CalibrationSRGP(SingleDataInput(id),Val); 'SR-GP'
    T_SVD{id,1} =CalibrationSVD(SingleDataInput(id),Val,percentage);'SVD'
    save Example3.mat
end
%%
%Section 3: Show BO results
clc,clear
load('Example3.mat');
idx=(1:100);
BORecordTable=[T_MBC_AGP(idx)  T_BC_AGP(idx)   T_MID_AGP(idx)  T_SR_AGP(idx)   T_Nested(idx) T_SVDAGP(idx)   T_BC_GP(idx)  T_SR_GP(idx)  T_SVD(idx)    ];
Labels={'MBC-AGP','BC-AGP','MID-AGP','SR-AGP', 'Nested','SVD-AGP', 'BC-GP','SR-GP' ,'SVD'}' ;

for Trainidx=1:size(BORecordTable,1)
    for Methodidx=1:9
        Table=BORecordTable{Trainidx,Methodidx} ;
        
        DiffSSETrue_XhatsEnd(Trainidx,Methodidx)=Table.SSETrue_Xhats(end,:)-SSE_XMLE;
        SSETrue_XhatsEnd(Trainidx,Methodidx)=Table.SSETrue_Xhats(end,:);
        XhatsEnd=Table.Xhats(end,:);
        L2End(Trainidx,Methodidx)=norm(XhatsEnd-XMLE);
        if Methodidx<=2 || Methodidx==7
            phiEnd(Trainidx,Methodidx)=Table.phis(end,:);
        end
        
        costs=[1 RatioCost]';
        SSETrue_Xhats_iter=Table.SSETrue_Xhats;
        Xhats_iter=Table.Xhats;
        L2s_iter=sum((Xhats_iter-XMLE).^2,2).^0.5;
        Level_iter=Table.Level;
        Budget_iter=cumsum(costs(Level_iter));
        
        TrueSSE_Xhats_Budget(1:Budget,Methodidx,Trainidx) = interp1(Budget_iter,SSETrue_Xhats_iter,1:Budget);
        
        L2_Budget(1:Budget,Methodidx,Trainidx)=interp1(Budget_iter,L2s_iter,1:Budget);
        
        if Methodidx==5 || Methodidx==6
            deleteLFidx=(nl+nh+1):2:size(Table,1);
            Budget_iter(deleteLFidx,:)=[];
            SSETrue_Xhats_iter(deleteLFidx,:)=[];
            L2s_iter(deleteLFidx,:)=[];
            
            TrueSSE_Xhats_Budget(:,Methodidx,Trainidx) = interp1(Budget_iter,SSETrue_Xhats_iter,1:(Budget));
            L2_Budget(:,Methodidx,Trainidx)=interp1(Budget_iter,L2s_iter,1:(Budget));
        end
        
    end
end

meanTrueSSE_Xhats_Budget_SSEXMLE=mean(TrueSSE_Xhats_Budget,3)-SSE_XMLE;
meanL2_Budget=mean(L2_Budget,3);

idx1=1;
for idx2=1:9
    [ ~, ttest_p_Sh(idx2,1)]=ttest(SSETrue_XhatsEnd(:,idx1),SSETrue_XhatsEnd(:,idx2));
    [ ~, ttest_p_L2(idx2,1)]=ttest(L2End(:,idx1),L2End(:,idx2));
end

Table3 =table(Labels,mean(SSETrue_XhatsEnd)',ttest_p_Sh,mean(L2End)',ttest_p_L2)

Labels={'MBC-AGP              ','  BC-AGP         ','     MID-AGP       ', '    SR-AGP   ' ,  '   Nested   ' ,'   SVD-AGP','       BC-GP','       SR-GP','       SVD'}';
figure,clf
subplot(121)
boxplot(DiffSSETrue_XhatsEnd,'Labels',Labels)
bp= gca;bp.FontSize=20;
bpXAxisFontSize=17;
bp.XAxis.FontWeight='bold';bp.XAxis.FontSize=bpXAxisFontSize;
bp.YAxis.FontWeight='bold';bp.YAxis.FontSize=23;
hold on
ylim([0.00005,60])
set(gca,'YScale','log')
ylabel('$S_h(\hat{\textbf{x}}^*_{\mathbf{ML}})-0.093939$','FontWeight','bold','Interpreter','latex','FontSize',28);
set(findobj(gca,'type','line'),'linew',2)
title('(a)','FontSize',25,'FontWeight','bold')
set(gca,'Position',[0.07 0.12 0.42 0.8])
set(gca,'yGrid','on','GridLineStyle','--')
bp.GridLineStyle='--';
yticks([  10.^[-4:1]   50])
yticklabels({'10^{-4}','10^{-3}','10^{-2}', '10^{-1}','10^{0}','10^{1}'  '50'})
 set(gca,'TickLabelInterpreter', 'tex');

subplot(122)
boxplot( L2End,'Labels',Labels)
set(gca,'Position',[0.575 0.12 0.42 0.8])
set(findobj(gca,'type','line'),'linew',2)
bp= gca;bp.FontSize=20;
bp.XAxis.FontWeight='bold';bp.XAxis.FontSize=bpXAxisFontSize;
bp.YAxis.FontWeight='bold';bp.YAxis.FontSize=23;
ylabel('$L_2(\hat{\textbf{x}}^*_{\mathbf{ML}})$','Interpreter','latex','FontSize',28);
set(findobj(gcf,'type','axes'),'FontWeight','Bold', 'LineWidth', 2);
title('(b)','FontSize',25,'FontWeight','bold')
set(gcf,'position'  ,[          0         386        1920         510])
set(gca,'yGrid','on','GridLineStyle','--')
bp.GridLineStyle='--';
ylim([   0.00008    0.6])
set(gca,'YScale','log')
yticks([ 10.^[-4:-1] 0.5  ]  )
 
set(gca,'TickLabelInterpreter', 'tex');

Labels={'MBC-AGP','BC-AGP','MID-AGP', 'SR-AGP' ,  'Nested' ,'SVD-AGP','BC-GP','SR-GP','SVD'}';
FontSize=24;
figure,clf
tiledlayout(1,2,'Padding','none','TileSpacing','none');
nexttile
htmlGray = [128 128 128]/255;
htmlGreen = [0.4660 0.6740 0.1880];

MarkerSize=15;
linewidth=4;
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,1),'ko-','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget:3:Budget Budget]),hold on
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,2),'b:o','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerFaceColor','b','MarkerIndices',[InitialBudget (InitialBudget+2):2:Budget Budget]),
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,3),'k^-','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget):3:Budget Budget])
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,4),'--v','linewidth',linewidth,'Color', htmlGray,'MarkerSize',MarkerSize,'MarkerIndices',[(InitialBudget+1):2:Budget Budget]),hold on
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,5),':s','linewidth',linewidth,'color',htmlGreen,'MarkerFaceColor',htmlGreen,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget:4:Budget ])
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,6),'b-x','linewidth',linewidth,'MarkerSize',MarkerSize+10,'MarkerIndices',[InitialBudget (InitialBudget+1):3:Budget Budget])
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,7),':s','linewidth',linewidth,'Color', 'r','MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+2):3:Budget Budget ]),hold on
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,8),'--h','linewidth',linewidth,'MarkerFaceColor','none','MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+1):3:Budget Budget ]),hold on
plot(1:Budget,meanTrueSSE_Xhats_Budget_SSEXMLE(1:Budget,9),':d','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+3):3:Budget Budget ]),hold on

ylim([0.25 170])
set(gca,'FontWeight','bold','FontSize',FontSize,'YScale','log')
xlim([InitialBudget,Budget])
xlabel('Computational cost','FontWeight','normal')
ylabel('Average  $S_h(\hat{\textbf{x}}^*_{\mathbf{ML}})-0.093939$','Interpreter','latex','FontSize',32);
leg = legend(Labels,'NumColumns',3,'Location','northeast');
leg.ItemTokenSize = [74,50];
title('(a)','FontWeight','bold')
yticks([0.3 10.^[0:2] ])
yticklabels({'0.3 ', '10^0 ','10^1 ','10^2 '})
 set(gca,'TickLabelInterpreter', 'tex');
 
nexttile
plot(1:Budget,meanL2_Budget(1:Budget,1),'ko-','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget:3:Budget Budget]),hold on
plot(1:Budget,meanL2_Budget(1:Budget,2),'b:o','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerFaceColor','b','MarkerIndices',[InitialBudget (InitialBudget):2:Budget Budget]),
plot(1:Budget,meanL2_Budget(1:Budget,3),'k^-','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget):3:Budget Budget])
plot(1:Budget,meanL2_Budget(1:Budget,4),'--v','linewidth',linewidth,'Color', htmlGray,'MarkerSize',MarkerSize,'MarkerIndices',[(InitialBudget+1):2:Budget Budget]),hold on
plot(1:Budget,meanL2_Budget(1:Budget,5),':s','linewidth',linewidth,'color',htmlGreen,'MarkerFaceColor',htmlGreen,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget:4:Budget Budget])
plot(1:Budget,meanL2_Budget(1:Budget,6),'b-x','linewidth',linewidth,'MarkerSize',MarkerSize+10,'MarkerIndices',[InitialBudget (InitialBudget+1):3:Budget Budget])
plot(1:Budget,meanL2_Budget(1:Budget,7),':s','linewidth',linewidth,'Color', 'r','MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+2):3:Budget Budget ]),hold on
plot(1:Budget,meanL2_Budget(1:Budget,8),'--h','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+1):3:Budget Budget ]),hold on
plot(1:Budget,meanL2_Budget(1:Budget,9),':d','linewidth',linewidth,'MarkerSize',MarkerSize,'MarkerIndices',[InitialBudget (InitialBudget+3):3:Budget Budget ]),hold on
xlim([InitialBudget,Budget])
ylim([0.019    0.52])

xlabel('Computational cost','FontWeight','normal')
title('(b)','FontWeight','bold')
set(gca,'FontWeight','bold','FontSize',FontSize)
ylabel('Average  $L_2(\hat{\textbf{x}}^*_{\mathbf{ML}})$','Interpreter','latex','FontSize',32);
leg = legend(Labels,'NumColumns',3,'Location','northeast');
leg.ItemTokenSize = [74,50];
set(findobj(gcf,'type','axes'),'FontWeight','Bold', 'LineWidth', 3);
set(gca,'YScale','log')
yticks(0.01*2.^[1:5])
yticklabels({'0.02 ','0.04 ','0.08 ','0.16 ','0.32 '})
set(gcf,'Position',[          0         100        1920         615])


figure,clf
Labels2Method={'MBC-AGP','BC-AGP','BC-GP'};
boxplot( phiEnd(:,[1 2 7]), 'Labels',Labels2Method,'OutlierSize',10,'Widths',0.8*[1 1 1  ])
set(findobj(gca,'type','line'),'linew',2)
set(findobj(gcf,'type','axes'),'FontSize',27,'FontWeight','Bold', 'LineWidth', 2);
ylabel('$ \hat \varphi$','Interpreter','latex','FontSize',50,'Rotation',0,'HorizontalAlignment','right','VerticalAlignment','baseline')
set(gca,'Position',[    0.2    0.14    0.78    0.83])
set(gcf,'Position',[           409   559   900   410])
set(gcf,'Position',[           409   559   900   334])
set(findobj(gcf,'type','axes'),'FontWeight','Bold', 'LineWidth', 3);
yticks([-0.1:0.1:0.6])
set(gca,'yGrid','on','GridLineStyle','--')
ylim([-0.17 0.64])
set(gcf,'Position',[           109   159   900   372])
medians=median(phiEnd(:,[1 2 7]));
FontSize77=20;
text(1,1.11*medians(1),['Median=' num2str(medians(1),2)],'HorizontalAlignment','center','FontSize',FontSize77,'FontWeight','Bold')
text(2,1.1*medians(2),['Median=' num2str(medians(2),2)],'HorizontalAlignment','center','FontSize',FontSize77,'FontWeight','Bold')
text(3,1.14*medians(3),['Median=' num2str(medians(3),2)],'HorizontalAlignment','center','FontSize',FontSize77,'FontWeight','Bold')
xlim([0.45 3.55])


figure;clf
Labels={'MBC-AGP','BC-AGP','MID-AGP', 'SR-AGP' ,  'Nested' ,'SVD-AGP','BC-GP','SR-GP','SVD'}';
Trainidx=88
tiledlayout(2,10,'Padding','none','TileSpacing','none');
pd1=1;
pd2=2;
Fontsize=18;
linewidth=1;

for Methodidx =[1:6]
    if Methodidx ==6
        nexttile([1 1])
        axis off

        nexttile([1 2])
    else
        
    nexttile([1 2])
    end
    
    Table=BORecordTable{Trainidx,Methodidx};
    XhatsEnd=Table.Xhats(end,:);
    Level=Table.Level;
    
    Dh=Table.D(Level==2,:);
    Dl=Table.D(Level==1,:);
    
    
    InitialDh=Dh(1:nh,:);
    InitialDl=Dl(1:nl,:);
    FollowDh=Dh(nh+1:end,:);
    FollowDl=Dl(nl+1:end,:);
    
    plot(InitialDh(:,pd1),InitialDh(:,pd2),'bs','linewidth',linewidth,'markersize',15)
    hold on
    plot(InitialDl(:,pd1),InitialDl(:,pd2),'bx','linewidth',linewidth,'markersize',15)
    
    plot(FollowDh(:,pd1),FollowDh(:,pd2),'ko','linewidth',linewidth,'markersize',15)
    hold on
    plot(FollowDl(:,pd1),FollowDl(:,pd2),'k+','linewidth',linewidth,'markersize',15)
    
    
    xlabel('x_1','FontSize',Fontsize)
    ylabel('x_2','FontSize',Fontsize,'Rotation',0,'HorizontalAlignment','right')
    xticks([0:0.2:1])
    yticks([0:0.2:1])
    
    xygird0=0.03;
    xlim([-xygird0 1+xygird0])
    ylim([-xygird0 1+xygird0])
    
    plot(XhatsEnd(:,pd1),XhatsEnd(:,pd2),'k^','MarkerSize',25)
    hold on
    plot(XMLE(:,pd1),XMLE(:,pd2),'kp','MarkerSize',25)
    
    title(Labels(Methodidx),'FontWeight','Bold')
end


for Methodidx =7:9
    
    Table=BORecordTable{Trainidx,Methodidx};
    XhatsEnd=Table.Xhats(end,:);
    
    Dh=Table.D;
    InitialDh=Dh(1:nh0,:);
    FollowDh=Dh(nh0+1:end,:);
    
    nexttile([1 2])
    
    pd1=1;
    pd2=2;
    
    plot(XMLE(:,pd1),XMLE(:,pd2),'kp','MarkerSize',25)
    hold on
    plot(XhatsEnd(:,pd1),XhatsEnd(:,pd2),'k^','MarkerSize',25)
    
    
    plot(InitialDh(:,pd1),InitialDh(:,pd2),'bs','linewidth',linewidth,'markersize',15)
    hold on
    plot(FollowDh(:,pd1),FollowDh(:,pd2),'ko','linewidth',linewidth,'markersize',15)
    
    xlabel('x_1','FontSize',Fontsize)
    ylabel('x_2','FontSize',Fontsize,'Rotation',0,'HorizontalAlignment','right')
    
    xticks([0:0.2:1])
    yticks([0:0.2:1])
    
    xygird0=0.03;
    xlim([-xygird0 1+xygird0])
    ylim([-xygird0 1+xygird0])
    
    title(Labels(Methodidx),'FontWeight','Bold')
end
set(findobj(gcf,'type','axes'),'FontSize',Fontsize,'FontWeight','Bold', 'LineWidth', 1);
set(gcf,'Position',[          0         0        1600         700])