classdef PduParams_MCP < PduParams &  matlab.mixin.SetGet
    % Object defining CCM parameters - encapsulates various dependent
    % calculations of rates and volumes. 
    
    properties (Dependent)
        % Non-dimensional params
        % See supplementary material and pdf document NonDimEqns2 for how these
        % Formulas contain the cytosol solutions.
        xi      % ratio of rate of diffusion across cell to rate of 
                %dehydration reaction of carbonic anhydrase (D/Rc^2)/(VCDE/KPQ)
        gamma   % ratio of PduP/PduQ and PduCDE max rates (2*VPQ)/(VCDE)
        kappa   % ratio of 1/2 max PduCDE and 1/2 max PduP/PduQ concentrations (KCDE/KPQ)
        beta_a  % da/d\rho = beta_a*a + epsilon_a
        beta_p  % dp/d\rho = beta_p*p + epsilon_p
        epsilon_a % da/d\rho = beta_a*a + epsilon_a
        epsilon_p % dp/d\rho = beta_p*p + epsilon_p
        Xa  % grouped params = D/(Rc^2 kcA) + 1/Rc - 1/Rb [1/cm]
        Xp  % grouped params = D/(Rc^2 kcP) + 1/Rc - 1/Rb [1/cm]
        
        % Calculated appropriate to the volume in which the enzymes are
        % contained which depends on the situation (in cbsome or not).
        VCDE    % uM/s PduCDE max reaction rate/concentration
        VPQ     % maximum rate of aldehyde consumption by PduP/PduQ
    end
    
    methods
        function obj = PduParams_MCP()
            obj@PduParams(); 
        end
        
        function jc = CalcOptimalJc(obj, Hmax)
            p = obj;
            Hcytop = @(jc) calcHcytoDiff_Csome(jc, p, Hmax);
            jc = fzero(Hcytop, 1e-2); 
        end
        
        function value = get.VCDE(obj)
            value = obj.VCDEMCP;
        end
        function value = get.VPQ(obj)
            value = obj.VPQMCP;
        end
        
        function value = get.xi(obj)
            value = obj.D * obj.KPQ / (obj.VCDEMCP * obj.Rc^2);
        end
        function value = get.gamma(obj)
            value = 2*obj.VPQMCP / obj.VCDEMCP;
        end
        function value = get.kappa(obj)
            value = obj.KCDE / obj.KPQ;
        end
        
        function value = get.Xa(obj)
            value = (obj.D/(obj.kcA*obj.Rc^2) + 1/obj.Rc - 1/obj.Rb);
        end
        function value = get.Xp(obj)
            value = (obj.D/(obj.kcP*obj.Rc^2) + 1/obj.Rc - 1/obj.Rb);
        end

        function value = get.beta_a(obj)
            value = -1/(obj.Rc*(obj.D/(obj.kmA*obj.Rb^2)+obj.Xa));
        end
        function value = get.epsilon_a(obj)
            value = obj.Aout/(obj.KPQ*obj.Rc*(obj.D/(obj.kmA*obj.Rb^2)+obj.Xa));
        end
        
        function value = get.epsilon_p(obj)
            value = obj.Pout*(obj.jc+obj.kmP)/(obj.KCDE*obj.Rc*(obj.D/obj.Rb^2+obj.kmP*obj.Xp));
        end
        function value = get.beta_p(obj)
            value = -obj.kmP/(obj.Rc*(obj.D/obj.Rb^2+obj.kmP*obj.Xp));
        end
        
    end
end