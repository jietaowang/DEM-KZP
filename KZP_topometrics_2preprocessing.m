%% (2) Calculating flow direction, flow accumulation, relief and other topographic metrics
%
fprintf(1,'KZP topometrics step 2 of 4: pre-processing DEM: %s\n', KZP_parameters.DEM_fname);
if exist(KZP_parameters.DEM_HYD_MAT_fname, 'file') == 0 || KZP_parameters.REGEN == 1
    % Pre-process DEM (e.g., calculate flow direction, flow accumulation,
    % slope, and stream networks)
    if exist('AOI_FAC', 'var') ~= 1 || KZP_parameters.REGEN == 1
        [AOI_FIL, AOI_FD, AOI_FAC, AOI_STR_w, AOI_mg, AOI_rivers_STR, ...
            AOI_rivers_STR_area1, AOI_rivers_STR_area2, AOI_resolution, ...
            minApix, AOI_FAC_w, AOI_rivers_slope, AOI_rivers_area, AOI_rivers_w] = ...
            DEM_preprocess(AOI_DEM, KZP_parameters.REGEN, KZP_parameters.dir_sep, KZP_parameters.gdaldem_cmd, KZP_parameters.DEM_FIL_fname, ...
            KZP_parameters.DEM_FAC_fname, KZP_parameters.DEM_basename, KZP_parameters.area_threshold, KZP_parameters.min_str_gradient, ...
            KZP_parameters.str_area1, KZP_parameters.str_area2, KZP_parameters.min_drainage_area_to_process, KZP_parameters.geotiff_dirname, KZP_parameters.RELIEF_CURVATURE);
    end
    
    % delineate drainage basins
    if exist('AOI_dbasins_regionprops', 'var') ~= 1 || KZP_parameters.REGEN == 1
        [AOI_dbasins_regionprops, AOI_dbasins, AOI_dbasins_outlet] = ...
            BSN_calcstats(AOI_FD, KZP_parameters.min_dbasins_stats_to_process, KZP_parameters.DEM_dbasin_fname, KZP_parameters.REGEN);
    end
    
    % Calculate relief
    if KZP_parameters.RELIEF_CURVATURE == 1
        if exist('AOI_DEM_rel_3', 'var') ~= 1 || KZP_parameters.REGEN == 1
            [AOI_DEM_rel_1, AOI_DEM_rel_2, AOI_DEM_rel_3] = ...
                DEM_lrelief(AOI_DEM, KZP_parameters.relief_values_m, KZP_parameters.DEM_rel_1_fname, KZP_parameters.DEM_rel_2_fname, KZP_parameters.DEM_rel_3_fname, KZP_parameters.REGEN);
        end
    end
    
    % calculatute Curvature from unfiltered DEM
    if KZP_parameters.RELIEF_CURVATURE == 1
        if exist('AOI_DEM_curv_meanc', 'var') ~= 1 || KZP_parameters.REGEN == 1
            [AOI_DEM_curv_profc, AOI_DEM_curv_planc, AOI_DEM_curv_meanc] = ...
                DEM_curv(AOI_DEM, KZP_parameters.AOI_DEM_curv_profc_fname, KZP_parameters.AOI_DEM_curv_planc_fname, KZP_parameters.AOI_DEM_curv_meanc_fname, KZP_parameters.REGEN);
        end
    end
    
    % diffusion-filtering of DEM as described in Passalacqua et al. (2010a,
    % 2010b) and Perona and Malik (1990) and calculate curvature
    if KZP_parameters.RELIEF_CURVATURE == 1
        if exist('AOI_DEM_diffusionf', 'var') ~= 1 || KZP_parameters.REGEN == 1
            AOI_DEM_diffusionf = ...
                DEM_diffusionf(AOI_DEM, KZP_parameters.difkernelWidth, KZP_parameters.difSSquared, ...
                KZP_parameters.difTimeIncrement, KZP_parameters.difFilterI, KZP_parameters.difMethod, KZP_parameters.AOI_DEM_diff_fname, KZP_parameters.REGEN);
            AOI_DEM_diffusionf_curv = DEM_curv2(AOI_DEM_diffusionf, strcat(KZP_parameters.TIF_DIR_basename, '_diffusionf_curv.tif'));
        end
    end
    
    % Wiener filtering of DEM and calculate curvature
    if KZP_parameters.RELIEF_CURVATURE == 1
        if exist('AOI_DEM_wiener_curv', 'var') ~= 1 || KZP_parameters.REGEN == 1
            AOI_DEM_wiener = filter(AOI_DEM, 'wiener', [5 5]);
            AOI_DEM_wiener_curv = DEM_curv2(AOI_DEM_wiener, strcat(KZP_parameters.TIF_DIR_basename, '_wienerf_curv.tif'));
        end
    end
    
    %Calculate stream gradient and SSP
    if exist('AOI_SSP', 'var') ~= 1 || KZP_parameters.REGEN == 1
        [AOI_DEM_gradient8, AOI_Q, AOI_SSP] = ...
            DEM_SSP(AOI_mg, KZP_parameters.DEM_gradient8_fname, AOI_FAC, KZP_parameters.DEM_SSP_fname, KZP_parameters.REGEN, KZP_parameters.RELIEF_CURVATURE);
    end
    
    % extract ridgecrests
    if KZP_parameters.RIDGECREST == 1
        if exist('AOI_ridgecrest_MS', 'var') ~= 1 || REGEN == 1
            [AOI_ridgecrest_MS] = ...
                DEM_ridgecrest(AOI_dbasins_regionprops, AOI_dbasins, AOI_dbasins_outlet);
        end
    end
    
    %Get DEM and curvature values for ridgecrest
    if KZP_parameters.RIDGECREST == 1
        if exist('AOI_ridgecrest_DEM', 'var') ~= 1 || REGEN == 1
            [AOI_ridgecrest_DEM] = ...
                DEM_ridgevalues(AOI_ridgecrest_MS, AOI_DEM);
            [AOI_ridgecrest_diffusionf_curv] = ...
                DEM_ridgevalues(AOI_ridgecrest_MS, AOI_DEM_diffusionf_curv);
            [AOI_ridgecrest_wiener_curv] = ...
                DEM_ridgevalues(AOI_ridgecrest_MS, AOI_DEM_wiener_curv);
        end
    end
    
    % Analyze ridgecrests and get normalized profiles
    if KZP_parameters.RIDGECREST == 1
        if exist('AOI_ridgecrest_MS_deltay_all', 'var') ~= 1 || KZP_parameters.REGEN == 1
            [AOI_ridgecrest_MS, AOI_ridgecrest_MS_Dy_all, AOI_ridgecrest_MS_yi_all, ridgecrest_stepsize] = ...
                DEM_ridgecrest_analyze(AOI_ridgecrest_MS, AOI_ridgecrest_DEM, ...
                KZP_parameters.DEM_HYD_MAT_fname);
        end
    end
    
    if exist('AOI_ks_adj', 'var') ~= 1 || KZP_parameters.REGEN == 1
        [AOI_ksn045, AOI_ks_adj, AOI_slopearea] = ...
            DEM_ksn(KZP_parameters.theta, AOI_FAC, AOI_DEM_gradient8, AOI_rivers_STR, AOI_mg, KZP_parameters.DEM_ksn045_fname, KZP_parameters.DEM_ks_adj_fname);
    end
    
    %Generate Stream ORDER files for adding IDs to catchments
    if exist('AOI_STO_N', 'var') ~= 1 || KZP_parameters.REGEN == 1
        AOI_STO = streamorder(AOI_FD, AOI_rivers_w);
        for k = 1:length(KZP_parameters.stream_order)
            stream_order2use = KZP_parameters.stream_order(k);
            [AOI_STO_N{k}] = drainagebasins(AOI_FD, AOI_STO, stream_order2use);
            stream_order_label(k,:) = sprintf('STO%d',KZP_parameters.stream_order(k));
        end
    end
    
    %extract trunk stream
    if exist('AOI_STR_streams_dbasins_trunk_grid', 'var') ~= 1 || KZP_parameters.REGEN == 1
        AOI_STR_streams_dbasins = klargestconncomps(AOI_rivers_STR);
        AOI_STR_streams_dbasins_trunk = trunk(AOI_STR_streams_dbasins);
        AOI_STR_streams_dbasins_trunk_grid = STREAMobj2GRIDobj(AOI_STR_streams_dbasins_trunk);
        %idxnan = find(AOI_STR_streams_dbasins_trunk_grid.Z == 0);
        %AOI_STR_streams_dbasins_trunk_grid.Z(idxnan) = NaN;
    end
    
    if KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) > 1
        AOI_STR_MS = STREAMobj2mapstruct(AOI_rivers_STR, ...
            'seglength', KZP_parameters.segL, 'attributes',...
            {'ksn045' AOI_ksn045 @mean ...
            'ks_adj' AOI_ks_adj @mean ...
            'SSP' AOI_SSP @mean ...
            'rel1' AOI_DEM_rel_1 @mean ...
            'rel2' AOI_DEM_rel_2 @mean ...
            'rel3' AOI_DEM_rel_3 @mean ...
            'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
            'gradient' AOI_DEM_gradient8 @mean ...
            'elev' AOI_DEM @mean ...
            'elev_mg' AOI_mg @mean ...
            'prof_curv' AOI_DEM_curv_profc @mean ...
            'plan_curv' AOI_DEM_curv_planc @mean ...
            'mean_curv' AOI_DEM_curv_meanc @mean ...
            'diff_curv' AOI_DEM_diffusionf_curv @mean ...
            'wiene_curv' AOI_DEM_wiener_curv @mean ...
            stream_order_label(1,:) AOI_STO_N{1} @max ...
            stream_order_label(2,:) AOI_STO_N{2} @max ...
            'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max
            });

    elseif KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) == 1
        AOI_STR_MS = STREAMobj2mapstruct(AOI_rivers_STR, ...
            'seglength', KZP_parameters.segL, 'attributes',...
            {'ksn045' AOI_ksn045 @mean ...
            'ks_adj' AOI_ks_adj @mean ...
            'SSP' AOI_SSP @mean ...
            'rel1' AOI_DEM_rel_1 @mean ...
            'rel2' AOI_DEM_rel_2 @mean ...
            'rel3' AOI_DEM_rel_3 @mean ...
            'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
            'gradient' AOI_DEM_gradient8 @mean ...
            'elev' AOI_DEM @mean ...
            'elev_mg' AOI_mg @mean ...
            'prof_curv' AOI_DEM_curv_profc @mean ...
            'plan_curv' AOI_DEM_curv_planc @mean ...
            'mean_curv' AOI_DEM_curv_meanc @mean ...
            'diff_curv' AOI_DEM_diffusionf_curv @mean ...
            'wiene_curv' AOI_DEM_wiener_curv @mean ...
            stream_order_label(1,:) AOI_STO_N{1} @max ...
            'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max
            });
else
        AOI_STR_MS = STREAMobj2mapstruct(AOI_rivers_STR,...
            'seglength', KZP_parameters.segL, 'attributes',...
            {'ksn045' AOI_ksn045 @mean ...
            'ks_adj' AOI_ks_adj @mean ...
            'SSP' AOI_SSP @mean ...
            'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
            'gradient' AOI_DEM_gradient8 @mean ...
            'elev' AOI_DEM @mean ...
            'elev_mg' AOI_mg @mean ...
            });
    end
    
    if length(AOI_rivers_STR_area1.x) > 5
        if KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) > 1
            AOI_STR_MS_area1 = STREAMobj2mapstruct(AOI_rivers_STR_area1,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'rel1' AOI_DEM_rel_1 @mean ...
                'rel2' AOI_DEM_rel_2 @mean ...
                'rel3' AOI_DEM_rel_3 @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                'prof_curv' AOI_DEM_curv_profc @mean ...
                'plan_curv' AOI_DEM_curv_planc @mean ...
                'mean_curv' AOI_DEM_curv_meanc @mean ...
                'diff_curv' AOI_DEM_diffusionf_curv @mean ...
                'wiene_curv' AOI_DEM_wiener_curv @mean ...
                stream_order_label(1,:) AOI_STO_N{1} @max ...
                stream_order_label(2,:) AOI_STO_N{2} @max ...
                'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max
                });
        elseif KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) == 1
            AOI_STR_MS_area1 = STREAMobj2mapstruct(AOI_rivers_STR_area1,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'rel1' AOI_DEM_rel_1 @mean ...
                'rel2' AOI_DEM_rel_2 @mean ...
                'rel3' AOI_DEM_rel_3 @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                'prof_curv' AOI_DEM_curv_profc @mean ...
                'plan_curv' AOI_DEM_curv_planc @mean ...
                'mean_curv' AOI_DEM_curv_meanc @mean ...
                'diff_curv' AOI_DEM_diffusionf_curv @mean ...
                'wiene_curv' AOI_DEM_wiener_curv @mean ...
                stream_order_label(1,:) AOI_STO_N{1} @max ...
                'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max
                });
        else
            AOI_STR_MS_area1 = STREAMobj2mapstruct(AOI_rivers_STR_area1,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                });
        end
    else
        AOI_STR_MS_area1 = NaN;
    end
    
    if length(AOI_rivers_STR_area2.x) > 5
        if KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) > 1
            AOI_STR_MS_area2 = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'rel1' AOI_DEM_rel_1 @mean ...
                'rel2' AOI_DEM_rel_2 @mean ...
                'rel3' AOI_DEM_rel_3 @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                'prof_curv' AOI_DEM_curv_profc @mean ...
                'plan_curv' AOI_DEM_curv_planc @mean ...
                'mean_curv' AOI_DEM_curv_meanc @mean ...
                'diff_curv' AOI_DEM_diffusionf_curv @mean ...
                'wiene_curv' AOI_DEM_wiener_curv @mean ...
                stream_order_label(1,:) AOI_STO_N{1} @max ...
                stream_order_label(2,:) AOI_STO_N{2} @max ...
                'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max                
                });
            AOI_STR_MS_areaonly = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'attributes',...
                {'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                });
        elseif KZP_parameters.RELIEF_CURVATURE == 1 && size(stream_order_label,1) == 1
            AOI_STR_MS_area2 = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'rel1' AOI_DEM_rel_1 @mean ...
                'rel2' AOI_DEM_rel_2 @mean ...
                'rel3' AOI_DEM_rel_3 @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                'prof_curv' AOI_DEM_curv_profc @mean ...
                'plan_curv' AOI_DEM_curv_planc @mean ...
                'mean_curv' AOI_DEM_curv_meanc @mean ...
                'diff_curv' AOI_DEM_diffusionf_curv @mean ...
                'wiene_curv' AOI_DEM_wiener_curv @mean ...
                stream_order_label(1,:) AOI_STO_N{1} @max ...
                'TRUNK_ID' AOI_STR_streams_dbasins_trunk_grid @max                
                });

            AOI_STR_MS_areaonly = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'attributes',...
                {'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                });
        else
            AOI_STR_MS_area2 = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'seglength', KZP_parameters.segL, 'attributes',...
                {'ksn045' AOI_ksn045 @mean ...
                'ks_adj' AOI_ks_adj @mean ...
                'SSP' AOI_SSP @mean ...
                'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                });
            AOI_STR_MS_areaonly = STREAMobj2mapstruct(AOI_rivers_STR_area2,...
                'attributes',...
                {'uparea_m2' (AOI_FAC.*(AOI_FAC.cellsize^2)) @mean ...
                'gradient' AOI_DEM_gradient8 @mean ...
                'elev' AOI_DEM @mean ...
                'elev_mg' AOI_mg @mean ...
                });
        end
    else
        AOI_STR_MS_area2 = NaN;
    end
    
    fprintf(1,'\tsaving variables\n');
    % saves all variables so you don't need to repeat the time-intensive steps
    if KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 1
        save(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_FIL', 'AOI_FD', 'AOI_FAC', 'AOI_resolution', ...
            'minApix', 'AOI_FAC_w', 'AOI_STR_w', 'AOI_mg', 'AOI_STR_MS', ...
            'AOI_DEM_rel*', 'AOI_Q', 'AOI_SSP', 'AOI_DEM_gradient8', 'AOI_dbasins', ...
            'AOI_rivers_slope', 'AOI_rivers_area', 'AOI_ksn045', 'AOI_ks_adj', ...
            'AOI_slopearea', 'AOI_rivers_STR', 'AOI_rivers_STR_area1', ...
            'AOI_rivers_STR_area2', 'AOI_STR_MS_area1', 'AOI_STR_MS_area2', ...
            'AOI_STR_MS_areaonly', 'AOI_rivers_w', 'AOI_DEM_curv_*', 'AOI_DEM_wiene*', ...
            'AOI_DEM_diffusion*', 'AOI_ridgecres*', 'AOI_ridgecrest_MS', ...,
            'ridgecrest_stepsize', '-v7.3');
    elseif KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 0
        save(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_FIL', 'AOI_FD', 'AOI_FAC', 'AOI_resolution', ...
            'minApix', 'AOI_FAC_w', 'AOI_STR_w', 'AOI_mg', 'AOI_STR_MS', ...
            'AOI_DEM_rel*', 'AOI_Q', 'AOI_SSP', 'AOI_DEM_gradient8', 'AOI_dbasins', ...
            'AOI_rivers_slope', 'AOI_rivers_area', 'AOI_ksn045', 'AOI_ks_adj', ...
            'AOI_slopearea', 'AOI_rivers_STR', 'AOI_rivers_STR_area1', ...
            'AOI_rivers_STR_area2', 'AOI_STR_MS_area1', 'AOI_STR_MS_area2', ...
            'AOI_STR_MS_areaonly', 'AOI_rivers_w', 'AOI_DEM_curv_*', 'AOI_DEM_wiene*', ...
            'AOI_DEM_diffusion*', '-v7.3');
    else
        save(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_FIL', 'AOI_FD', 'AOI_FAC', 'AOI_resolution', ...
            'minApix', 'AOI_FAC_w', 'AOI_STR_w', 'AOI_mg', 'AOI_STR_MS', ...
            'AOI_Q', 'AOI_SSP', 'AOI_DEM_gradient8', 'AOI_dbasins', ...
            'AOI_rivers_slope', 'AOI_rivers_area', 'AOI_ksn045', 'AOI_ks_adj', ...
            'AOI_slopearea', 'AOI_rivers_STR', 'AOI_rivers_STR_area1', ...
            'AOI_STR_MS_areaonly', 'AOI_rivers_STR_area2', 'AOI_STR_MS_area1', ...
            'AOI_STR_MS_area2', 'AOI_rivers_w', '-v7.3');
    end
elseif exist(KZP_parameters.DEM_HYD_MAT_fname, 'file') == 2
    if exist('AOI_STR_MS', 'var') ~= 1 && KZP_parameters.show_figs ~= 2
        load(KZP_parameters.DEM_HYD_MAT_fname)
    end
end

if KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 1
    load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
        'AOI_STR_MS*', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', 'AOI_STR_MS_areaonly', ...
        'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', ...
        'AOI_slopearea', 'AOI_ridgecres*', 'ridgecrest_stepsize');
    BSN_writeshapefiles_long(KZP_parameters.DEM_basename, KZP_parameters.dir_sep, KZP_parameters.DEM_basename_nodir, KZP_parameters.DEM_fname, ...
        str_area1, str_area2, KZP_parameters.gdalsrsinfo_cmd, KZP_parameters.ogr2ogr_cmd, KZP_parameters.remove_cmd, KZP_parameters.mv_cmd, AOI_STR_MS, ...
        AOI_STR_MS_area1, AOI_STR_MS_area2, AOI_STR_MS_areaonly, AOI_ridgecrest_MS, AOI_ridgecrest_DEM);
    
    shapeout_fn_prj = sprintf('%s%s%s_%s_PT_proj.shp', KZP_parameters.shapefile_dirname, ...
        KZP_parameters.dir_sep, KZP_parameters.DEM_basename, num2str(KZP_parameters.area_threshold,'%1.0e'));
    if exist(shapeout_fn_prj, 'file') ~= 2 || KZP_parameters.REGEN == 1
        DEM_FAC_pt_export(AOI_DEM, AOI_FAC, KZP_parameters.area_threshold, AOI_FD, ...
            AOI_mg, KZP_parameters.dir_sep, KZP_parameters.DEM_basename, KZP_parameters.gdalsrsinfo_cmd, KZP_parameters.ogr2ogr_cmd, KZP_parameters.remove_cmd, KZP_parameters.mv_cmd);
    end
elseif KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 0
    load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
        'AOI_STR_MS*', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', 'AOI_STR_MS_areaonly', ...
        'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', 'AOI_slopearea');
    BSN_writeshapefiles_long(KZP_parameters.shapefile_dirname, KZP_parameters.dir_sep, KZP_parameters.DEM_basename, KZP_parameters.DEM_basename_nodir, KZP_parameters.DEM_fname, ...
        KZP_parameters.str_area1, KZP_parameters.str_area2, KZP_parameters.gdalsrsinfo_cmd, KZP_parameters.ogr2ogr_cmd, KZP_parameters.remove_cmd, KZP_parameters.mv_cmd, AOI_STR_MS, ...
        AOI_STR_MS_area1, AOI_STR_MS_area2, AOI_STR_MS_areaonly);
    
    shapeout_fn_prj = sprintf('%s%s%s_%s_PT_proj.shp', ...
        KZP_parameters.shapefile_dirname, KZP_parameters.dir_sep, KZP_parameters.DEM_basename, num2str(KZP_parameters.area_threshold,'%1.0e'));
    if exist(shapeout_fn_prj, 'file') ~= 2 || KZP_parameters.REGEN == 1
        DEM_FAC_pt_export(KZP_parameters.shapefile_dirname, AOI_DEM, AOI_FAC, KZP_parameters.area_threshold, AOI_FD, ...
            AOI_mg, KZP_parameters.dir_sep, KZP_parameters.DEM_basename, KZP_parameters.gdalsrsinfo_cmd, KZP_parameters.ogr2ogr_cmd, KZP_parameters.remove_cmd, KZP_parameters.mv_cmd);
    end
else
    load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
        'AOI_STR_MS*', 'AOI_slopearea');
    BSN_writeshapefiles_short(KZP_parameters.dir_sep, KZP_parameters.DEM_basename, KZP_parameters.DEM_basename_nodir, KZP_parameters.DEM_fname, ...
        KZP_parameters.str_area1, KZP_parameters.str_area2, KZP_parameters.gdalsrsinfo_cmd, KZP_parameters.ogr2ogr_cmd, KZP_parameters.remove_cmd, KZP_parameters.mv_cmd, AOI_STR_MS, ...
        AOI_STR_MS_area1, AOI_STR_MS_area2, AOI_STR_MS_areaonly);
end

% Create figures showing DEM, hillshade, and river network, save as PDF:
if KZP_parameters.show_figs == 1 || KZP_parameters.show_figs == 2
    if KZP_parameters.show_figs == 2
        load(KZP_parameters.DEM_MAT_fname)
        if KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 1
            if exist('AOI_DEM_gradient8') ~= 1 || exist('AOI_ridgecres*') ~= 1 || exist('AOI_rivers_STR_area2') ~= 1 || ...
                    exist('AOI_STR_MS') ~= 1 || exist('AOI_DEM_curv_*') ~= 1 || exist('AOI_DEM_rel_2') ~= 1 || exist('AOI_DEM_wiener_curv') ~= 1 || ...
                    exist('AOI_DEM_diffusionf_curv') ~= 1 || exist('AOI_slopearea') ~= 1
                load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
                    'AOI_STR_MS', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', ...
                    'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', ...
                    'AOI_slopearea', 'AOI_ridgecres*', 'ridgecrest_stepsize', 'AOI_rivers_STR_area2');
            end
        elseif KZP_parameters.RELIEF_CURVATURE == 1 || KZP_parameters.RIDGECREST == 0
            if exist('AOI_DEM_gradient8') ~= 1 || exist('AOI_rivers_STR') ~= 1 || exist('AOI_rivers_STR_area2') ~= 1 || ...
                    exist('AOI_STR_MS') ~= 1 || exist('AOI_DEM_curv_*') ~= 1 || exist('AOI_DEM_rel_2') ~= 1 || exist('AOI_DEM_wiener_curv') ~= 1 || ...
                    exist('AOI_DEM_diffusionf_curv') ~= 1 || exist('AOI_slopearea') ~= 1
                load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
                    'AOI_STR_MS', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', ...
                    'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', 'AOI_rivers_STR_area2', ...
                    'AOI_slopearea');
            end
        end
    end
    if KZP_parameters.show_figs == 1
        if KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 1
            if exist('AOI_DEM_gradient8') ~= 1 || exist('AOI_rivers_STR') ~= 1 || exist('AOI_rivers_STR_area2') ~= 1 || ...
                    exist('AOI_STR_MS') ~= 1 || exist('AOI_DEM_curv_*') ~= 1 || exist('AOI_DEM_rel_2') ~= 1 || exist('AOI_DEM_wiener_curv') ~= 1 || ...
                    exist('AOI_DEM_diffusionf_curv') ~= 1 || exist('AOI_slopearea') ~= 1
                load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
                    'AOI_STR_MS', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', ...
                    'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', ...
                    'AOI_slopearea', 'AOI_ridgecres*', 'ridgecrest_stepsize', 'AOI_rivers_STR_area2');
            end
        elseif KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 0
            if exist('AOI_DEM_gradient8') ~= 1 || exist('AOI_rivers_STR') ~= 1 || exist('AOI_rivers_STR_area2') ~= 1 || ...
                    exist('AOI_STR_MS') ~= 1 || exist('AOI_DEM_curv_*') ~= 1 || exist('AOI_DEM_rel_2') ~= 1 || exist('AOI_DEM_wiener_curv') ~= 1 || ...
                    exist('AOI_DEM_diffusionf_curv') ~= 1 || exist('AOI_slopearea') ~= 1
                load(KZP_parameters.DEM_HYD_MAT_fname, 'AOI_DEM_gradient8', 'AOI_rivers_STR', ...
                    'AOI_STR_MS', 'AOI_DEM_curv_*', 'AOI_DEM_rel_2', ...
                    'AOI_DEM_wiener_curv', 'AOI_DEM_diffusionf_curv', 'AOI_rivers_STR_area2', ...
                    'AOI_slopearea');
            end
        end
    end
    if KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 1
        DEM_mkfigures_long(KZP_parameters.MATLABV, KZP_parameters.PaperType_size, KZP_parameters.quality_flag, KZP_parameters.DEM_basename_nodir, ...
            AOI_DEM, KZP_parameters.DEM_basename_no_underscore, AOI_rivers_STR_area2, AOI_DEM_gradient8, ...
            AOI_DEM_curv_profc, AOI_DEM_curv_planc, AOI_DEM_curv_meanc, ...
            AOI_DEM_wiener_curv, AOI_DEM_diffusionf_curv, AOI_STR_MS, ...
            AOI_DEM_rel_2, KZP_parameters.relief_values_m, AOI_slopearea, KZP_parameters.dir_sep, KZP_parameters.plots_dirname, KZP_parameters.map_dirname, AOI_ridgecrest_MS, ...
            AOI_ridgecrest_DEM, AOI_ridgecrest_MS_Dy_all, ...
            AOI_ridgecrest_MS_yi_all, KZP_parameters.ridgecrest_stepsize, KZP_parameters.map_dirname)
    elseif KZP_parameters.RELIEF_CURVATURE == 1 && KZP_parameters.RIDGECREST == 0
        DEM_mkfigures_long(KZP_parameters.MATLABV, KZP_parameters.PaperType_size, KZP_parameters.quality_flag, KZP_parameters.DEM_basename_nodir, ...
            AOI_DEM, KZP_parameters.DEM_basename_no_underscore, AOI_rivers_STR_area2, AOI_DEM_gradient8, ...
            AOI_DEM_curv_profc, AOI_DEM_curv_planc, AOI_DEM_curv_meanc, ...
            AOI_DEM_wiener_curv, AOI_DEM_diffusionf_curv, AOI_STR_MS, ...
            AOI_DEM_rel_2, KZP_parameters.relief_values_m, AOI_slopearea, KZP_parameters.dir_sep, KZP_parameters.plots_dirname, KZP_parameters.map_dirname)
    else
        DEM_mkfigures_short(KZP_parameters.MATLABV, KZP_parameters.PaperType_size, KZP_parameters.quality_flag, KZP_parameters.DEM_basename_nodir, ...
            AOI_DEM, KZP_parameters.DEM_basename_no_underscore, AOI_rivers_STR_area2, AOI_DEM_gradient8, ...
            AOI_STR_MS, AOI_slopearea)
    end
end

if KZP_parameters.manual_select_basin == 1
    basin_index = DEM_select_DB(AOI_dbasins);
end

clear AOI_FIL AOI_resolution AOI_FAC_w AOI_STR_w ...
    AOI_DEM_rel* AOI_Q AOI_SSP AOI_DEM_curv_* ...
    AOI_rivers_slope AOI_rivers_area AOI_ksn045 AOI_ks_adj ...
    AOI_slopearea AOI_rivers_STR AOI_rivers_STR_area1 ...
    AOI_rivers_STR_area2 AOI_STR_MS_area1AOI_STR_MS_area2 AOI_DEM_wiene* ...
    AOI_DEM_diffusion AOI_ridgecres* AOI_ridgecrest_MS
