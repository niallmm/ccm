classdef NumericalCCMModelSolution
    % Concentrations are in (TxN) matrices where T is the number of
    % timepoints and N is the number of points along the radius of the cell
    % considered in the discretization of the cell.
    properties
        ccm_params;     % params used to solve the model
        
        % Concentrations. Meaning depends on the model run. If you are
        % running a model with a carboxysome, then these are the
        % carboxysomal concentrations. If it is a whole cell model (i.e. no
        % carboxysome) then these are cytoplasmic. 
        h_nondim;       % nondimensional concentration of total bicarbonate over time and space.
        c_nondim;       % nondimensional concentration of co2 over time and space.
        h_mM;           % mM concentration of total bicarbonate over time and space.
        c_mM;           % mM concentration of co2 over time and space.
        c_csome_mM;     % mM concentration of CO2 at center of carboxysome
        h_csome_mM;     % mM concentration of HCO3- at center of carboxysome
        c_csome_uM;     % uM concentration of CO2 at center of carboxysome
        h_csome_uM;     % uM concentration of HCO3- at center of carboxysome   
        c_cyto_uM;      % uM concentration of CO2 across the cytosol
        h_cyto_uM;      % uM concentration of HCO3- across the cytosol 
        c_cyto_mM;      % mM concentration of CO2 across the cytosol
        h_cyto_mM;      % mM concentration of HCO3- across the cytosol 
        
        fintime;        % final time of the numerical solution -- needs to be long enough to get to steady state
        t;              % vector of time values the numerical solver solved at -- this is only meaningful to check that we reached steady state
        r;              % radial points for concentration values inside carboxysome
        rb;             % radial points between carboxysome and cell membrane

    end
    
    methods
        function obj = NumericalCCMModelSolution(ccm_params, r, h_nondim, c_nondim, fintime, t)
            obj.ccm_params = ccm_params;
            obj.h_nondim = h_nondim;
            obj.c_nondim = c_nondim;
            obj.r = r;
            obj.t = t;
            obj.fintime = fintime;
            obj.h_mM = obj.DimensionalizeHTomM(h_nondim);
            obj.c_mM = obj.DimensionalizeCTomM(c_nondim);
            
            % concentrations at center of compartment
            obj.c_csome_mM = obj.c_mM(end,1);
            obj.h_csome_mM = obj.h_mM(end,1);
            obj.h_csome_uM = obj.h_csome_mM*1e3;
            obj.c_csome_uM = obj.c_csome_mM*1e3;
            
            % radial points between carboxysome and cell membrane
            obj.rb = linspace(obj.ccm_params.Rc, obj.ccm_params.Rb, 1e3);
            
            % concentrations at boundary of the cell
            
            obj.c_cyto_uM = (obj.ccm_params.kmC*obj.ccm_params.Cout - (obj.ccm_params.alpha+obj.ccm_params.kmC)*obj.c_csome_uM)*(obj.ccm_params.D/(obj.ccm_params.kcC*obj.ccm_params.Rc^2)+1/obj.ccm_params.Rc -1./obj.rb)/...
                ((obj.ccm_params.alpha+obj.ccm_params.kmC)*obj.ccm_params.GC + obj.ccm_params.D/obj.ccm_params.Rb^2) + obj.c_csome_uM;
            obj.h_cyto_uM = ((obj.ccm_params.jc+obj.ccm_params.kmH)*obj.ccm_params.Hout + obj.ccm_params.alpha*obj.c_cyto_uM(end) - obj.ccm_params.kmH*obj.h_csome_uM)*...
                (obj.ccm_params.D/(obj.ccm_params.kcC*obj.ccm_params.Rc^2)+1/obj.ccm_params.Rc -1./obj.rb)/(obj.ccm_params.kmH*obj.ccm_params.GH + obj.ccm_params.D/obj.ccm_params.Rb^2) + obj.h_csome_uM;
            obj.h_cyto_mM = obj.h_cyto_uM*1e-3;
            obj.c_cyto_mM = obj.c_cyto_uM*1e-3;
        end
        
        % Converts C to mM from non-dimensional units
        function val = DimensionalizeCTomM(obj, c_nondim)
            p = obj.ccm_params;  % shorthand
            val = c_nondim * p.Kca * 1e-3;
        end
        
        % Converts H to mM from non-dimensional units
        function val = DimensionalizeHTomM(obj, h_nondim)
            p = obj.ccm_params;  % shorthand
            val = h_nondim * p.Kba * 1e-3;
        end
    end
    
end
