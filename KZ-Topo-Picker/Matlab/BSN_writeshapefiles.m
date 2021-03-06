function BSN_writeshapefiles(dir_sep, DEM_basename, DEM_basename_nodir, DEM_fname, AOI_STR_MS, ...
    AOI_STR_MS_area1, AOI_STR_MS_area2, AOI_ridgecrest_MS, AOI_ridgecrest_DEM, ...
    str_area1, str_area2, gdalsrsinfo_cmd, ogr2ogr_cmd, remove_cmd, mv_cmd)

shapeout_fn = sprintf('shapefiles%s%s_all_MS.shp', dir_sep, DEM_basename);
shapeout_fn_ogr = sprintf('shapefiles%s%s_all_MS.out', dir_sep, DEM_basename);
shapeout_all_fn = sprintf('shapefiles%s%s_all_MS.*', dir_sep, DEM_basename);
shapeout_fn_prj = sprintf('shapefiles%s%s_all_MS_proj.shp', dir_sep, DEM_basename);
if exist(shapeout_fn_prj, 'file') ~= 2
    fprintf(1,'\twriting shapefile: %s\n', shapeout_fn);
    shapewrite(AOI_STR_MS,shapeout_fn);
    %Because shapewrite doesn't add projection information, we have to add
    %these manually via ogr2ogr or ArcMAP (or something similar)
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj ', ...
        shapeout_fn_prj, ' ', shapeout_fn, ' > ', shapeout_fn_ogr]);
    eval([remove_cmd, ' ', shapeout_all_fn]);
end

shapeout_fn = sprintf('shapefiles%s%s_MS_%s.shp', dir_sep, ...
    DEM_basename, num2str(str_area1,'%1.0G'));
shapeout_fn_out = sprintf('shapefiles%s%s_MS_%s.out', dir_sep, ...
    DEM_basename, num2str(str_area1,'%1.0G'));
shapeout_all_fn = sprintf('shapefiles%s%s_MS_%s.*', dir_sep, ...
    DEM_basename, num2str(str_area1,'%1.0G'));
k = strfind(shapeout_fn, '+'); shapeout_fn(k) = [];
shapeout_all_fn(k) = []; shapeout_fn_out(k) = [];
shapeout_fn_prj = sprintf('shapefiles%s%s_%s_MS_proj.shp', ...
    dir_sep, DEM_basename, num2str(str_area1,'%1.0e'));
if exist(shapeout_fn_prj, 'file') ~= 2
    fprintf(1,'\twriting shapefile: %s\n', shapeout_fn);
    if isstruct(AOI_STR_MS_area1)
        if ~isempty(AOI_STR_MS_area1)
            shapewrite(AOI_STR_MS_area1, shapeout_fn);
            %Because shapewrite doesn't add projection information, we have to add
            %these manually via ogr2ogr or ArcMAP (or something similar)
            eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
            eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj ', ...
                shapeout_fn_prj, ' ', shapeout_fn, ' > ', shapeout_fn_out]);
            eval([remove_cmd, ' ', shapeout_all_fn]);
        end
    end
end

shapeout_fn = sprintf('shapefiles%s%s_MS_%s.shp', dir_sep, ...
    DEM_basename, num2str(str_area2,'%1.0G'));
shapeout_fn_out = sprintf('shapefiles%s%s_MS_%s.out', dir_sep, ...
    DEM_basename, num2str(str_area2,'%1.0G'));
shapeout_all_fn = sprintf('shapefiles%s%s_MS_%s.*', dir_sep, ...
    DEM_basename, num2str(str_area2,'%1.0G'));
k = strfind(shapeout_fn, '+'); shapeout_fn(k) = [];
shapeout_all_fn(k) = []; shapeout_fn_out(k) = [];
shapeout_fn_prj = sprintf('shapefiles%s%s_%s_MS_proj.shp', dir_sep, ...
    DEM_basename, num2str(str_area2,'%1.0e'));
if exist(shapeout_fn_prj, 'file') ~= 2
    fprintf(1,'\twriting shapefile: %s\n', shapeout_fn);
    if isstruct(AOI_STR_MS_area2)
        if ~isempty(AOI_STR_MS_area2)
            shapewrite(AOI_STR_MS_area2, shapeout_fn);
            %Because shapewrite doesn't add projection information, we have to add
            %these manually via ogr2ogr or ArcMAP (or something similar)
            eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
            eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj ', ...
                shapeout_fn_prj, ' ', shapeout_fn, ' >', shapeout_fn_out]);
            eval([remove_cmd, ' ', shapeout_all_fn]);
        end
    end
end

% write all ridgecrest data as POINT CSV
precision = '%8.5f';
AOI_ridgecrest_MS_csv_fname = strcat(DEM_basename, '_ridgecrest_MS.csv');
AOI_ridgecrest_MS_Dy1_mean_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.csv');
AOI_ridgecrest_MS_Dy1_parab_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.csv');
AOI_ridgecrest_MS_Dy1_cosh2_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.csv');
AOI_ridgecrest_MS_Dy1_cosh4_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.csv');
AOI_ridgecrest_MS_Dy2_mean_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.csv');
no_header_yet_2std = 0;
if exist(AOI_ridgecrest_MS_csv_fname, 'file') ~= 2
    fprintf('\tWriting ridgecrest csv files\n');
    for i = 1:length(AOI_ridgecrest_MS)
        if length(AOI_ridgecrest_MS(i).x) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist', '6dist_norm', '7elev', '8elev_norm'};
            org_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).x), 1)) ...
                double(AOI_ridgecrest_MS(i).x) double(AOI_ridgecrest_MS(i).y) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).x), 1))...
                double(AOI_ridgecrest_MS(i).distance) double(AOI_ridgecrest_MS(i).distance_norm) ...
                double(AOI_ridgecrest_DEM(i).values) double(AOI_ridgecrest_DEM(i).values_norm)]);
            %ones(length(AOI_ridgecrest_MS(i).y), 1).* i ...
            if i == 1
                csvwrite_with_headers(AOI_ridgecrest_MS_csv_fname,org_matrix,headers,precision);
            else
                dlmwrite(AOI_ridgecrest_MS_csv_fname, org_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers org_matrix
        end
        
        if length(AOI_ridgecrest_MS(i).Dy_mean_lg_1std) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist_Dy1', '6elevi_nrm', '7Dy1_mn'};
            deltay_lg1_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).Dy_mean_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).x(AOI_ridgecrest_MS(i).Dy_mean_lg_1std)) ...
                double(AOI_ridgecrest_MS(i).y(AOI_ridgecrest_MS(i).Dy_mean_lg_1std)) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).Dy_mean_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).distance_Dy_mean_lg_1std)' ...
                double(AOI_ridgecrest_MS(i).elev_norm(AOI_ridgecrest_MS(i).Dyi_mean_lg_1std)') ...
                double(AOI_ridgecrest_MS(i).Dy_mean(AOI_ridgecrest_MS(i).Dyi_mean_lg_1std)')]);
            %write header the first time, then just append
            if i == 1
                csvwrite_with_headers(AOI_ridgecrest_MS_Dy1_mean_csv_fname,deltay_lg1_matrix,headers,precision);
            else
                dlmwrite(AOI_ridgecrest_MS_Dy1_mean_csv_fname, deltay_lg1_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers deltay_lg1_matrix
        end
        
        if length(AOI_ridgecrest_MS(i).Dy_mean_lg_2std) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist_Dy2', '6elevi_nrm', '7Dy2_mn'};
            deltay_lg2_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).Dy_mean_lg_2std), 1)) ...
                double(AOI_ridgecrest_MS(i).x(AOI_ridgecrest_MS(i).Dy_mean_lg_2std)) ...
                double(AOI_ridgecrest_MS(i).y(AOI_ridgecrest_MS(i).Dy_mean_lg_2std)) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).Dy_mean_lg_2std), 1)) ...
                double(AOI_ridgecrest_MS(i).distance_Dy_mean_lg_2std)' ...
                double(AOI_ridgecrest_MS(i).elev_norm(AOI_ridgecrest_MS(i).Dyi_mean_lg_2std)') ...
                double(AOI_ridgecrest_MS(i).Dy_mean(AOI_ridgecrest_MS(i).Dyi_mean_lg_2std)')]);
            %write header the first time, then just append
            if i == 1 || no_header_yet_2std == 0
                csvwrite_with_headers(AOI_ridgecrest_MS_Dy2_mean_csv_fname,deltay_lg2_matrix,headers,precision);
                no_header_yet_2std = 1;
            else
                dlmwrite(AOI_ridgecrest_MS_Dy2_mean_csv_fname, deltay_lg2_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers deltay_lg2_matrix
        end
        
        if length(AOI_ridgecrest_MS(i).Dy_parab_lg_1std) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist_Dy1', '6elevi_nrm', '7Dy1_parab'};
            deltay_lg1_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).Dy_parab_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).x(AOI_ridgecrest_MS(i).Dy_parab_lg_1std)) ...
                double(AOI_ridgecrest_MS(i).y(AOI_ridgecrest_MS(i).Dy_parab_lg_1std)) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).Dy_parab_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).distance_Dy_parab_lg_1std)' ...
                double(AOI_ridgecrest_MS(i).elev_norm(AOI_ridgecrest_MS(i).Dyi_parab_lg_1std)') ...
                double(AOI_ridgecrest_MS(i).Dy_parab(AOI_ridgecrest_MS(i).Dyi_parab_lg_1std)')]);
            %write header the first time, then just append
            if i == 1
                csvwrite_with_headers(AOI_ridgecrest_MS_Dy1_parab_csv_fname,deltay_lg1_matrix,headers,precision);
            else
                dlmwrite(AOI_ridgecrest_MS_Dy1_parab_csv_fname, deltay_lg1_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers deltay_lg1_matrix
        end
        
        if length(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist_Dy1', '6elevi_nrm', '7Dy1_cosh2'};
            deltay_lg1_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).x(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std)) ...
                double(AOI_ridgecrest_MS(i).y(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std)) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).distance_Dy_cosh2_lg_1std)' ...
                double(AOI_ridgecrest_MS(i).elev_norm(AOI_ridgecrest_MS(i).Dyi_cosh2_lg_1std)') ...
                double(AOI_ridgecrest_MS(i).Dy_cosh2(AOI_ridgecrest_MS(i).Dyi_cosh2_lg_1std)')]);
            %write header the first time, then just append
            if i == 1
                csvwrite_with_headers(AOI_ridgecrest_MS_Dy1_cosh2_csv_fname,deltay_lg1_matrix,headers,precision);
            else
                dlmwrite(AOI_ridgecrest_MS_Dy1_cosh2_csv_fname, deltay_lg1_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers deltay_lg1_matrix
        end
        
        if length(AOI_ridgecrest_MS(i).Dy_cosh2_lg_1std) > 100
            headers = {'1ID', '2X', '3Y', '4Area', '5dist_Dy1', '6elevi_nrm', '7Dy1_cosh4'};
            deltay_lg1_matrix = double([double(repmat(AOI_ridgecrest_MS(i).ID, length(AOI_ridgecrest_MS(i).Dy_cosh4_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).x(AOI_ridgecrest_MS(i).Dy_cosh4_lg_1std)) ...
                double(AOI_ridgecrest_MS(i).y(AOI_ridgecrest_MS(i).Dy_cosh4_lg_1std)) ...
                double(repmat(AOI_ridgecrest_MS(i).area, length(AOI_ridgecrest_MS(i).Dy_cosh4_lg_1std), 1)) ...
                double(AOI_ridgecrest_MS(i).distance_Dy_cosh4_lg_1std)' ...
                double(AOI_ridgecrest_MS(i).elev_norm(AOI_ridgecrest_MS(i).Dyi_cosh4_lg_1std)') ...
                double(AOI_ridgecrest_MS(i).Dy_cosh4(AOI_ridgecrest_MS(i).Dyi_cosh4_lg_1std)')]);
            %write header the first time, then just append
            if i == 1
                csvwrite_with_headers(AOI_ridgecrest_MS_Dy1_cosh4_csv_fname,deltay_lg1_matrix,headers,precision);
            else
                dlmwrite(AOI_ridgecrest_MS_Dy1_cosh4_csv_fname, deltay_lg1_matrix,'-append','delimiter',',','precision', precision);
            end
            clear headers deltay_lg1_matrix
        end
    end
end

AOI_ridgecrest_MS_csv_fname = strcat(DEM_basename, '_ridgecrest_MS.csv');
AOI_ridgecrest_MS_shape_fname = strcat(DEM_basename, '_ridgecrest_MS.shp');
AOI_ridgecrest_MS_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS.out');
AOI_ridgecrest_MS_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS.*');
AOI_ridgecrest_MS_crt_fname = strcat(DEM_basename, '_ridgecrest_MS.crt');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_FID = fopen(AOI_ridgecrest_MS_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6dist_norm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7elev" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="8elev_norm" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS'), AOI_ridgecrest_MS_csv_fname);
    fwrite(AOI_ridgecrest_MS_FID, string2write);
    fclose(AOI_ridgecrest_MS_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_shape_fname, ' ', AOI_ridgecrest_MS_crt_fname, ' 2> ', AOI_ridgecrest_MS_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);

AOI_ridgecrest_MS_deltay1_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.out');
AOI_ridgecrest_MS_Dy1_mean_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.csv');
AOI_ridgecrest_MS_deltay1_shape_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.shp');
AOI_ridgecrest_MS_deltay1_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.*');
AOI_ridgecrest_MS_deltay1_crt_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_1std.crt');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_deltay1_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_deltay1_FID = fopen(AOI_ridgecrest_MS_deltay1_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist_Dy1" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6elevi_nrm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7Dy1_mn" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS_Dy_mean_1std'), AOI_ridgecrest_MS_Dy1_mean_csv_fname);
    fwrite(AOI_ridgecrest_MS_deltay1_FID, string2write);
    fclose(AOI_ridgecrest_MS_deltay1_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_deltay1_shape_fname, ' ', AOI_ridgecrest_MS_deltay1_crt_fname, ' 2> ', AOI_ridgecrest_MS_deltay1_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_deltay1_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);

AOI_ridgecrest_MS_deltay1_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.out');
AOI_ridgecrest_MS_Dy1_parab_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.csv');
AOI_ridgecrest_MS_deltay1_shape_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.shp');
AOI_ridgecrest_MS_deltay1_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.*');
AOI_ridgecrest_MS_deltay1_crt_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_parab_1std.crt');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_deltay1_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_deltay1_FID = fopen(AOI_ridgecrest_MS_deltay1_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist_Dy1" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6elevi_nrm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7Dy1_parab" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS_Dy_parab_1std'), AOI_ridgecrest_MS_Dy1_parab_csv_fname);
    fwrite(AOI_ridgecrest_MS_deltay1_FID, string2write);
    fclose(AOI_ridgecrest_MS_deltay1_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_deltay1_shape_fname, ' ', AOI_ridgecrest_MS_deltay1_crt_fname, ' 2> ', AOI_ridgecrest_MS_deltay1_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_deltay1_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);

AOI_ridgecrest_MS_deltay1_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.out');
AOI_ridgecrest_MS_Dy1_cosh2_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.csv');
AOI_ridgecrest_MS_deltay1_shape_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.shp');
AOI_ridgecrest_MS_deltay1_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.*');
AOI_ridgecrest_MS_deltay1_crt_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh2_1std.crt');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_deltay1_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_deltay1_FID = fopen(AOI_ridgecrest_MS_deltay1_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist_Dy1" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6elevi_nrm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7Dy1_cosh2" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS_Dy_cosh2_1std'), AOI_ridgecrest_MS_Dy1_cosh2_csv_fname);
    fwrite(AOI_ridgecrest_MS_deltay1_FID, string2write);
    fclose(AOI_ridgecrest_MS_deltay1_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_deltay1_shape_fname, ' ', AOI_ridgecrest_MS_deltay1_crt_fname, ' 2> ', AOI_ridgecrest_MS_deltay1_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_deltay1_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);

AOI_ridgecrest_MS_deltay1_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.out');
AOI_ridgecrest_MS_Dy1_cosh4_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.csv');
AOI_ridgecrest_MS_deltay1_shape_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.shp');
AOI_ridgecrest_MS_deltay1_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.*');
AOI_ridgecrest_MS_deltay1_crt_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_cosh4_1std.crt');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_deltay1_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_deltay1_FID = fopen(AOI_ridgecrest_MS_deltay1_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist_Dy1" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6elevi_nrm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7Dy1_cosh4" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS_Dy_cosh4_1std'), AOI_ridgecrest_MS_Dy1_cosh4_csv_fname);
    fwrite(AOI_ridgecrest_MS_deltay1_FID, string2write);
    fclose(AOI_ridgecrest_MS_deltay1_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_deltay1_shape_fname, ' ', AOI_ridgecrest_MS_deltay1_crt_fname, ' 2> ', AOI_ridgecrest_MS_deltay1_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_deltay1_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);

AOI_ridgecrest_MS_Dy2_mean_csv_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.csv');
AOI_ridgecrest_MS_deltay2_shape_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.shp');
AOI_ridgecrest_MS_deltay2_shape_fname_all = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.*');
AOI_ridgecrest_MS_deltay2_crt_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.crt');
AOI_ridgecrest_MS_deltay2_shapeout_fname = strcat(DEM_basename, '_ridgecrest_MS_Dy_mean_2std.out');
if exist(strcat(sprintf('shapefiles%s', dir_sep),AOI_ridgecrest_MS_deltay2_shape_fname), 'file') ~= 2
    AOI_ridgecrest_MS_deltay2_FID = fopen(AOI_ridgecrest_MS_deltay2_crt_fname, 'w+');
    string2write = sprintf(['<OGRVRTDataSource>\n  <OGRVRTLayer name=\"%s\">\n', ...
        '    <SrcDataSource relativeToVRT=\"1\">%s</SrcDataSource>\n', ...
        '    <GeometryType>wkbPoint</GeometryType>\n', ...
        '    <LayerSRS>WGS84</LayerSRS>\n',...
        '    <GeometryField encoding="PointFromColumns" x="2X" y="3Y"/>\n',...
        '    <Field name="1ID" type="Integer" width="8"/>\n', ...
        '    <Field name="2X" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="3Y" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="4Area" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="5dist_Dy2" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="6elevi_nrm" type="Real" width="8" precision="7"/>\n', ...
        '    <Field name="7Dy2_mn" type="Real" width="8" precision="7"/>\n', ...
        '  </OGRVRTLayer>\n', '</OGRVRTDataSource>\n'], ...
        strcat(DEM_basename_nodir, '_ridgecrest_MS_Dy_mean_2std'), AOI_ridgecrest_MS_Dy2_mean_csv_fname);
    fwrite(AOI_ridgecrest_MS_deltay2_FID, string2write);
    fclose(AOI_ridgecrest_MS_deltay2_FID);
    eval([gdalsrsinfo_cmd, ' -o wkt ', DEM_fname, '> projection.prj']);
    eval([ogr2ogr_cmd, ' -s_srs projection.prj -t_srs projection.prj -f "ESRI Shapefile" ', ...
        AOI_ridgecrest_MS_deltay2_shape_fname, ' ', AOI_ridgecrest_MS_deltay2_crt_fname, ' 2> ', AOI_ridgecrest_MS_deltay2_shapeout_fname]);
end
eval([mv_cmd, ' ', AOI_ridgecrest_MS_deltay2_shape_fname_all, ' ', sprintf('shapefiles%s', dir_sep)]);
