function transformed_coords=transform_gaze(calibration, coords)

x=coords(:,1);
y=coords(:,2);    
transformed_coords=[calibration.betaX(1)+calibration.betaX(2)*(x.*y)+calibration.betaX(3)*x+calibration.betaX(4)*y,...
    calibration.betaY(1)+calibration.betaY(2)*(x.*y)+calibration.betaY(3)*x+calibration.betaY(4)*y];