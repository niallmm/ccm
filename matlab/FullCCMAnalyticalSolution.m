classdef FullCCMAnalyticalSolution
    % Calculates the Analytic Solutions for the whole CCM
    % pH dependence of Carbonic Anhydrase only enabled for the carbonic
    % anhydrase unsaturated solutions.
    properties
        ccm_params;     % params used to solve the model
        h_cyto_uM;      % uM concentration of total bicarbonate in cytoplasm.
        c_cyto_uM;      % uM concentration of CO2 in cytoplasm.
        h_cyto_mM;      % mM concentration of total bicarbonate in cytoplasm.
        c_cyto_mM;      % mM concentration of CO2 in cytoplasm.
        h_csome_uM;     % uM concentration of total bicarbonate in carboxysome.
        c_csome_uM;     % uM concentration of CO2 in carboxysome.
        h_csome_mM;     % mM concentration of total bicarbonate in carboxysome.
        c_csome_mM;     % mM concentration of CO2 in carboxysome.
        
        % =================================================================
        % Calculate CO2 and O2 fixation rates for whole cell
        VO;             % [uM/s] maximum rate of oxygen fixation calculated from the specificity of RuBisCO
        % intgrated over carboxysome volume
        CratewO_um;        % [um/s] rate of CO2 fixation with oxygen accounted for
        OratewC_um;        % [um/s] rate of O2 fication with CO2 accounted for
        CratewO_pm;        % [pmole/s] rate of CO2 fixation with oxygen accounted for
        OratewC_pm;        % [pmole/s] rate of O2 fication with CO2 accounted for
        % =================================================================
        % Calculate CO2 and HCO3- flux rates at cell membrane
        % integrated over surface area of cell
        Hin_pm;            % [pmole/s] rate of active uptake of HCO3- jc*Hout
        Hleak_pm;          % [pmole/s] rate of HCO3- leakage out of cell kmH*(Hout-Hcyto)
        Cleak_pm;          % [pmole/s] rate of CO2 leakage out of cell kmC*(Cout-Ccyto)
        Hin_um;            % [um/s]
        Hleak_um;          % [um/s]
        Cleak_um;          % [um/s]
        
        error;             % the proportion of oxygen fixations to total fixation events
    end
    
    methods
        function obj = FullCCMAnalyticalSolution(ccm_params)
            obj.ccm_params = ccm_params;
            
            % Calculate analytic solutions
            p = ccm_params;
            
            N = (p.jc + p.kmH)*p.Hout*((p.kmC+p.alpha)*p.G + p.D/p.Rb^2) ...
                + p.kmC*p.Cout*((p.kmH+p.alpha)*p.G +p.D/p.Rb^2);
            M = (p.kmC + p.alpha)*(1+1/p.Keq)*p.kmH*p.G + ...
                p.kmC*(1+(p.kmH/p.kmC)/p.Keq)*p.D/p.Rb^2;
            P = ((p.alpha + p.kmC)*p.G + p.D/p.Rb^2).*(p.kmH*p.G + p.D/p.Rb^2);
            
            Ccsomep = 0.5*(N./M - p.Rc^3*p.Vmax*P./(3*M*p.D) - p.Km) ...
                + 0.5*sqrt((-N./M + p.Rc^3*p.Vmax*P./(3*M*p.D) + p.Km).^2 + 4*N*p.Km./M);
            Hcsome = Ccsomep/p.Keq;
            
            % saturated CA forward reaction
            
            CCAsat0 = p.Vba*(p.Rc^3)*(p.G+p.D/((p.alpha+p.kmC)*p.Rb^2))/(3*p.D) + ...
                p.Vba*(p.Rc^2)/(6*p.D) + p.kmC*p.Cout/(p.alpha+p.kmC);
            
            HCAsat0 = -p.Vba*(p.Rc^2)/p.D -p.Vba*(p.Rc^3)*(p.G+p.D/(p.kmH*p.Rb^2))/(3*p.D)...
                +(p.jc+p.kmH)*p.Hout/p.kmH + p.alpha*p.kmC*p.Cout./(p.kmH*((p.alpha + p.kmC)*p.G+p.D/p.Rb^2)) ...
                +(p.alpha-(p.alpha*(p.alpha+p.kmC)*p.G./((p.alpha+p.kmC)*p.G+p.D/p.Rb^2))).*CCAsat0/p.kmH;
            % determine whether CA is saturated and choose apporpriate
            % analytic solution
            diff = Ccsomep - CCAsat0;
            if  Ccsomep > CCAsat0 || (abs(diff)/(Ccsomep+CCAsat0) <1e-3)
                obj.c_csome_uM = CCAsat0;
                obj.h_csome_uM = HCAsat0;
                warning('Carbonic anhydrase is unsaturated, so if you are trying to use the pH dependence this is bad')
%                 csat = 1
            elseif Ccsomep<CCAsat0
                obj.c_csome_uM = Ccsomep;
                obj.h_csome_uM = Hcsome;
%                 CAunsat =1
            end
            
            % concentration in the cytosol at r = Rb
            obj.c_cyto_uM = (p.kmC*p.Cout - (p.alpha+p.kmC)*obj.c_csome_uM)*p.G/...
                ((p.alpha+p.kmC)*p.G + p.D/p.Rb^2) +obj.c_csome_uM;
            
           obj.h_cyto_uM = ((p.jc+p.kmH)*p.Hout + p.alpha*obj.c_cyto_uM - ...
               p.kmH*obj.h_csome_uM)*p.G/(p.kmH*p.G + p.D/p.Rb^2)+obj.h_csome_uM;
            
           % unit conversion to mM
           obj.h_cyto_mM = obj.h_cyto_uM * 1e-3;
            obj.c_cyto_mM = obj.c_cyto_uM * 1e-3;
            obj.h_csome_mM = obj.h_csome_uM * 1e-3;
            obj.c_csome_mM = obj.c_csome_uM * 1e-3;
            
            p = ccm_params;
            C = obj.c_csome_uM;
            obj.VO = p.Vmax*p.KO/(p.Km*p.S_sat);
            obj.CratewO_pm = p.Vmax*C./(C+p.Km*(1+p.O/p.KO))*p.Vcsome*1e3;
            obj.CratewO_um = p.Vmax*C./(C+p.Km*(1+p.O/p.KO))*p.Vcsome*1e-3; % convert from uM*cm^3 to umoles
            obj.OratewC_pm = obj.VO*p.O./(p.O+p.KO*(1+C/p.Km))*p.Vcsome*1e3;
            obj.OratewC_um = obj.VO*p.O./(p.O+p.KO*(1+C/p.Km))*p.Vcsome*1e-3;
            
            obj.Hin_pm = p.jc*p.Hout*p.SAcell*1e3;
            obj.Hleak_pm = p.kmH*(p.Hout - obj.h_cyto_uM)*p.SAcell*1e3;
            obj.Cleak_pm = p.kmC*(p.Cout - obj.c_cyto_uM)*p.SAcell*1e3;
            obj.Hin_um = p.jc*p.Hout*p.SAcell*1e-3;
            obj.Hleak_um = p.kmH*(p.Hout - obj.h_cyto_uM)*p.SAcell*1e-3;
            obj.Cleak_um = p.kmC*(p.Cout - obj.c_cyto_uM)*p.SAcell*1e-3;
            
            obj.error = obj.OratewC_pm/(obj.CratewO_pm + obj.OratewC_pm);
        end
        
    end
    
end

